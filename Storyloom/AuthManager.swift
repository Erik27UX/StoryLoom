import SwiftUI
import Combine
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "erikfischer.Storyloom", category: "Auth")

// MARK: - AuthManager
// Handles Supabase authentication. Login and signup are async throws.
// Role updates, profile updates, logout, and onboarding remain synchronous
// public API (fire-and-forget internally) so existing callers don't need changes.

final class AuthManager: ObservableObject {

    static let shared = AuthManager()

    // MARK: Published state

    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var hasCompletedOnboarding: Bool = false
    /// True while we are checking for an existing Supabase session on launch.
    /// Show a splash / loading screen while this is true.
    @Published var isCheckingAuth: Bool = true
    /// Current user's role — mirrors currentUser?.role but guaranteed to trigger @Published updates.
    @Published var currentUserRole: UserRole = .reader
    /// True when the user arrived via a password-reset link and needs to set a new password.
    @Published var isPasswordRecovery: Bool = false

    // MARK: Internal state

    /// The Supabase auth UID (UUID from auth.users). Separate from the local SwiftData User.id.
    private(set) var supabaseUserId: UUID?

    private let onboardingKey = "hasCompletedOnboarding"
    private let cachedProfileKey = "cachedUserProfile"
    private var authListenerTask: Task<Void, Never>?

    // MARK: Init

    private init() {
        logger.debug("init called")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        logger.debug("starting auth listener...")
        startAuthListener()
        logger.debug("init complete")
    }

    // MARK: - Auth State Listener

    private func startAuthListener() {
        authListenerTask = Task { @MainActor in
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                logger.debug("auth event: \(String(describing: event))")
                switch event {
                case .initialSession:
                    logger.debug("initialSession event, session exists: \(session != nil)")
                    if let session {
                        await self.handleSession(session)
                    } else {
                        self.isCheckingAuth = false
                    }

                case .signedIn:
                    logger.debug("signedIn event, session exists: \(session != nil)")
                    if let session {
                        await self.handleSession(session)
                    }
                    self.isCheckingAuth = false

                case .signedOut:
                    logger.debug("signedOut event")
                    self.clearUser()
                    self.isCheckingAuth = false

                case .passwordRecovery:
                    logger.debug("passwordRecovery event")
                    // User tapped a reset-password link — show the new password screen.
                    self.isPasswordRecovery = true
                    self.isCheckingAuth = false

                case .tokenRefreshed:
                    logger.debug("tokenRefreshed event")
                    if let session {
                        self.supabaseUserId = session.user.id
                    }

                default:
                    logger.debug("unhandled auth event")
                    break
                }
            }
        }
    }

    // MARK: - Session Handling

    @MainActor
    private func handleSession(_ session: Session) async {
        logger.debug("handleSession called")
        supabaseUserId = session.user.id

        do {
            logger.debug("fetching profile...")
            let profile: SupabaseProfile = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value

            logger.debug("profile fetched successfully")
            let user = buildUser(from: profile, session: session)
            currentUser = user
            isLoggedIn = true
            cacheProfile(profile)
            isCheckingAuth = false

            // Pull latest data from Supabase now that we have a valid session
            SyncManager.shared.pullAllUserData()

        } catch {
            logger.debug("profile not found — creating for new user")
            // Profile doesn't exist yet (first sign-in after email confirmation).
            // Create it now — user is authenticated so RLS will pass.
            let metadata = session.user.userMetadata
            let name = (metadata["name"]?.value as? String) ?? ""
            let role = (metadata["role"]?.value as? String) ?? UserRole.reader.rawValue
            let newProfile = SupabaseProfile(
                id: session.user.id,
                email: session.user.email,
                name: name,
                birthYear: nil,
                role: role,
                subscriptionTier: "free",
                profilePhotoURL: nil
            )
            do {
                try await SupabaseManager.shared.client
                    .from("profiles")
                    .insert(newProfile)
                    .execute()
                logger.debug("profile created successfully")
                let user = buildUser(from: newProfile, session: session)
                currentUser = user
                isLoggedIn = true
                cacheProfile(newProfile)
            } catch {
                logger.error("failed to create profile: \(error.localizedDescription, privacy: .private)")
                if let user = loadCachedUser(session: session) {
                    currentUser = user
                    isLoggedIn = true
                }
            }
            isCheckingAuth = false
        }
    }

    private func buildUser(from profile: SupabaseProfile, session: Session) -> User {
        var subscriptionTier = SubscriptionTier(rawValue: profile.subscriptionTier ?? "free") ?? .free

        #if DEBUG
        // Dev-account overrides — these emails always receive the specified tier
        // regardless of what is stored in Supabase. Remove before App Store submission.
        let devTierOverrides: [String: SubscriptionTier] = [
            "erikfischer27@gmail.com": .family
        ]
        if let email = profile.email ?? session.user.email,
           let override = devTierOverrides[email] {
            subscriptionTier = override
        }
        #endif

        // Paid users always open to storyteller on launch (they can switch in-session).
        // Free users open to whatever role is saved in their profile.
        let role: UserRole
        if subscriptionTier == .premium || subscriptionTier == .family {
            role = .storyteller
        } else {
            role = UserRole(rawValue: profile.role) ?? .reader
        }

        let user = User(
            email: profile.email ?? session.user.email ?? "",
            name: profile.name ?? "",
            role: role
        )
        user.subscriptionTier = subscriptionTier
        user.birthYear = profile.birthYear
        user.profilePhotoURL = profile.profilePhotoURL

        // Save name and subscription tier to AppStorage for display throughout app
        UserDefaults.standard.set(user.name, forKey: "userName")
        UserDefaults.standard.set(user.subscriptionTier.rawValue, forKey: "subscriptionTier")
        UserDefaults.standard.set(user.role.rawValue, forKey: "userRole")

        // Keep currentUserRole in sync (drives ContentView tab structure)
        currentUserRole = role

        return user
    }

    // MARK: - Sync Auth Methods (async throws)

    func login(email: String, password: String) async throws {
        try await SupabaseManager.shared.client.auth.signIn(
            email: email,
            password: password
        )
        // handleSession is called automatically by the auth state listener
    }

    func signup(email: String, password: String, name: String, role: UserRole = .reader) async throws {
        logger.debug("signup starting")

        try await SupabaseManager.shared.client.auth.signUp(
            email: email,
            password: password,
            data: [
                "name": .string(name),
                "role": .string(role.rawValue)
            ],
            redirectTo: URL(string: "storyloom://auth/callback")
        )

        // Profile is created in handleSession once the user confirms their email
        // and a valid session exists — RLS requires auth.uid() to match the profile id.
        logger.debug("signup complete — confirmation email sent")
    }

    // MARK: - Fire-and-Forget Auth Methods (synchronous public API)

    func logout() {
        Task { @MainActor in
            try? await SupabaseManager.shared.client.auth.signOut()
            SyncManager.shared.clearLocalData()   // wipe cached stories/comments before next user logs in
            LikeManager.shared.clearAll()
            clearUser()
            hasCompletedOnboarding = false
            UserDefaults.standard.removeObject(forKey: onboardingKey)
            UserDefaults.standard.removeObject(forKey: cachedProfileKey)
        }
    }

    /// Permanently deletes the user's account and all their data via a Supabase RPC.
    /// Requires the `delete_user_account` SQL function to be created in Supabase first.
    func deleteAccount() {
        Task { @MainActor in
            do {
                try await SupabaseManager.shared.client
                    .rpc("delete_user_account")
                    .execute()
                logger.debug("account deleted from Supabase")
            } catch {
                logger.error("deleteAccount RPC failed: \(error.localizedDescription, privacy: .private)")
            }
            // Clear everything locally regardless of network result
            try? await SupabaseManager.shared.client.auth.signOut()
            SyncManager.shared.clearLocalData()   // wipe cached stories/comments
            LikeManager.shared.clearAll()
            clearUser()
            hasCompletedOnboarding = false
            UserDefaults.standard.removeObject(forKey: onboardingKey)
            UserDefaults.standard.removeObject(forKey: cachedProfileKey)
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func updateUserRole(_ role: UserRole) {
        guard var user = currentUser else { return }
        user.role = role
        currentUser = user
        currentUserRole = role

        // Paid users' in-session switches are local-only — buildUser() always
        // resets them to storyteller on next launch, so writing to Supabase is a no-op.
        let tier = user.subscriptionTier
        if tier == .premium || tier == .family { return }

        guard let uid = supabaseUserId else { return }
        Task {
            try? await SupabaseManager.shared.client
                .from("profiles")
                .update(ProfileRoleUpdate(role: role.rawValue))
                .eq("id", value: uid.uuidString)
                .execute()
        }
    }

    func updateUserProfile(name: String, birthYear: Int?, profilePhotoURL: String?) {
        guard var user = currentUser else { return }
        user.name = name
        user.birthYear = birthYear
        user.profilePhotoURL = profilePhotoURL
        currentUser = user

        guard let uid = supabaseUserId else { return }
        Task {
            try? await SupabaseManager.shared.client
                .from("profiles")
                .update(ProfileNameUpdate(name: name, birthYear: birthYear))
                .eq("id", value: uid.uuidString)
                .execute()
        }
    }

    /// Updates the subscription tier locally and writes it to Supabase.
    ///
    /// ⚠️  SECURITY NOTE — called ONLY from `#if DEBUG` code in UpgradeView for local testing.
    /// In production, subscription_tier must NEVER be written from the client.
    /// When RevenueCat is wired up, replace this with a backend webhook (RevenueCat → Supabase
    /// Edge Function via service_role key) so the client cannot self-upgrade.
    /// The Supabase RLS migration (supabase_security_migration.sql) blocks this write in production.
    func updateSubscriptionTier(_ tier: SubscriptionTier) {
        guard var user = currentUser else { return }
        user.subscriptionTier = tier
        currentUser = user

        guard let uid = supabaseUserId else { return }
        Task {
            try? await SupabaseManager.shared.client
                .from("profiles")
                .update(ProfileTierUpdate(subscriptionTier: tier.rawValue))
                .eq("id", value: uid.uuidString)
                .execute()
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private func clearUser() {
        currentUser = nil
        isLoggedIn = false
        supabaseUserId = nil
        currentUserRole = .reader
    }

    // MARK: - Local Profile Cache (offline fallback)

    private func cacheProfile(_ profile: SupabaseProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: cachedProfileKey)
    }

    private func loadCachedUser(session: Session) -> User? {
        guard let data = UserDefaults.standard.data(forKey: cachedProfileKey),
              let profile = try? JSONDecoder().decode(SupabaseProfile.self, from: data) else {
            // Minimal fallback from session only
            let user = User(email: session.user.email ?? "", name: "")
            return user
        }
        return buildUser(from: profile, session: session)
    }
}
