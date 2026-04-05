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
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        startAuthListener()
    }

    // MARK: - Auth State Listener

    private func startAuthListener() {
        authListenerTask = Task { @MainActor in
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let session {
                        await self.handleSession(session)
                    } else {
                        self.isCheckingAuth = false
                    }

                case .signedIn:
                    if let session {
                        await self.handleSession(session)
                    }
                    self.isCheckingAuth = false

                case .signedOut:
                    self.clearUser()
                    self.isCheckingAuth = false

                case .tokenRefreshed:
                    if let session {
                        self.supabaseUserId = session.user.id
                    }

                default:
                    break
                }
            }
        }
    }

    // MARK: - Session Handling

    @MainActor
    private func handleSession(_ session: Session) async {
        supabaseUserId = session.user.id

        do {
            let profile: SupabaseProfile = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value

            let user = buildUser(from: profile, session: session)
            currentUser = user
            isLoggedIn = true
            cacheProfile(profile)
            isCheckingAuth = false

            // Pull latest data from Supabase now that we have a valid session
            SyncManager.shared.pullAllUserData()

        } catch {
            // Profile may not exist yet (race on new signup) — fall back to cached
            if let user = loadCachedUser(session: session) {
                currentUser = user
                isLoggedIn = true
            }
            isCheckingAuth = false
        }
    }

    private func buildUser(from profile: SupabaseProfile, session: Session) -> User {
        let user = User(
            email: profile.email ?? session.user.email ?? "",
            name: profile.name ?? "",
            role: UserRole(rawValue: profile.role) ?? .reader
        )
        user.subscriptionTier = SubscriptionTier(rawValue: profile.subscriptionTier ?? "Free") ?? .free
        user.birthYear = profile.birthYear
        user.profilePhotoURL = profile.profilePhotoURL
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
        try await SupabaseManager.shared.client.auth.signUp(
            email: email,
            password: password,
            data: [
                "name": .string(name),
                "role": .string(role.rawValue)
            ]
        )
        // handleSession is called automatically by the auth state listener
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
        currentUser?.role = role
        currentUser?.subscriptionTier = role == .storyteller ? .premium : .free
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
        currentUser?.name = name
        currentUser?.birthYear = birthYear
        currentUser?.profilePhotoURL = profilePhotoURL
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
        currentUser?.subscriptionTier = tier
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
