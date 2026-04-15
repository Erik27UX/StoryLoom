import SwiftUI
import Combine
import Supabase

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

    // MARK: Internal state

    /// The Supabase auth UID (UUID from auth.users). Separate from the local SwiftData User.id.
    private(set) var supabaseUserId: UUID?

    private let onboardingKey = "hasCompletedOnboarding"
    private let cachedProfileKey = "cachedUserProfile"
    private var authListenerTask: Task<Void, Never>?

    // MARK: Init

    private init() {
        print("AuthManager: init called")
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        print("AuthManager: starting auth listener...")
        startAuthListener()
        print("AuthManager: init complete")
    }

    // MARK: - Auth State Listener

    private func startAuthListener() {
        authListenerTask = Task { @MainActor in
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                print("AuthManager: auth event: \(event)")
                switch event {
                case .initialSession:
                    print("AuthManager: initialSession event, session exists: \(session != nil)")
                    if let session {
                        await self.handleSession(session)
                    } else {
                        self.isCheckingAuth = false
                    }

                case .signedIn:
                    print("AuthManager: signedIn event, session exists: \(session != nil)")
                    if let session {
                        await self.handleSession(session)
                    }
                    self.isCheckingAuth = false

                case .signedOut:
                    print("AuthManager: signedOut event")
                    self.clearUser()
                    self.isCheckingAuth = false

                case .tokenRefreshed:
                    print("AuthManager: tokenRefreshed event")
                    if let session {
                        self.supabaseUserId = session.user.id
                    }

                default:
                    print("AuthManager: unknown auth event")
                    break
                }
            }
        }
    }

    // MARK: - Session Handling

    @MainActor
    private func handleSession(_ session: Session) async {
        print("AuthManager: handleSession called for user \(session.user.id.uuidString)")
        supabaseUserId = session.user.id

        do {
            print("AuthManager: fetching profile...")
            let profile: SupabaseProfile = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value

            print("AuthManager: profile fetched successfully")
            let user = buildUser(from: profile, session: session)
            currentUser = user
            isLoggedIn = true
            cacheProfile(profile)
            isCheckingAuth = false

            // Pull latest data from Supabase now that we have a valid session
            SyncManager.shared.pullAllUserData()

        } catch {
            print("AuthManager: handleSession profile not found — creating now for \(session.user.id)")
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
                subscriptionTier: "Free",
                profilePhotoURL: nil
            )
            do {
                try await SupabaseManager.shared.client
                    .from("profiles")
                    .insert(newProfile)
                    .execute()
                print("AuthManager: profile created successfully")
                let user = buildUser(from: newProfile, session: session)
                currentUser = user
                isLoggedIn = true
                cacheProfile(newProfile)
            } catch {
                print("AuthManager: failed to create profile — \(error.localizedDescription)")
                if let user = loadCachedUser(session: session) {
                    currentUser = user
                    isLoggedIn = true
                }
            }
            isCheckingAuth = false
        }
    }

    private func buildUser(from profile: SupabaseProfile, session: Session) -> User {
        let subscriptionTier = SubscriptionTier(rawValue: profile.subscriptionTier ?? "Free") ?? .free

        // Premium and Family tier users should always be storytellers
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
        print("AuthManager: signup starting for email: \(email)")

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
        print("AuthManager: signup complete — confirmation email sent")
    }

    // MARK: - Fire-and-Forget Auth Methods (synchronous public API)

    func logout() {
        Task { @MainActor in
            try? await SupabaseManager.shared.client.auth.signOut()
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
        user.subscriptionTier = role == .storyteller ? .premium : .free
        currentUser = user

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
