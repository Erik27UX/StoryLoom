import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var hasCompletedOnboarding = false

    private let userDefaultsKey = "currentUser"
    private let onboardingKey = "hasCompletedOnboarding"

    static let shared = AuthManager()

    private init() {
        loadUser()
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
    }

    // MARK: - Auth Methods

    func login(email: String, password: String, role: UserRole) {
        let user = User(email: email, name: email.components(separatedBy: "@").first ?? "", role: role)
        user.subscriptionTier = role == .storyteller ? .premium : .free
        currentUser = user
        isLoggedIn = true
        saveUser()
    }

    func signup(email: String, password: String, name: String, role: UserRole) {
        let user = User(email: email, name: name, role: role)
        user.subscriptionTier = role == .storyteller ? .premium : .free
        currentUser = user
        isLoggedIn = true
        saveUser()
    }

    func logout() {
        currentUser = nil
        isLoggedIn = false
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: onboardingKey)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func updateUserRole(_ role: UserRole) {
        currentUser?.role = role
        currentUser?.subscriptionTier = role == .storyteller ? .premium : .free
        saveUser()
    }

    func updateUserProfile(name: String, birthYear: Int?, profilePhotoURL: String?) {
        currentUser?.name = name
        currentUser?.birthYear = birthYear
        currentUser?.profilePhotoURL = profilePhotoURL
        saveUser()
    }

    // MARK: - Persistence

    private func saveUser() {
        guard let user = currentUser else { return }
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save user: \(error)")
        }
    }

    private func loadUser() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            currentUser = user
            isLoggedIn = true
        } catch {
            print("Failed to load user: \(error)")
        }
    }
}

// Extension to make User Codable
extension User: Codable {
    enum CodingKeys: String, CodingKey {
        case id, email, name, birthYear, role, subscriptionTier, profilePhotoURL, dateCreated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        try container.encode(birthYear, forKey: .birthYear)
        try container.encode(role.rawValue, forKey: .role)
        try container.encode(subscriptionTier.rawValue, forKey: .subscriptionTier)
        try container.encode(profilePhotoURL, forKey: .profilePhotoURL)
        try container.encode(dateCreated, forKey: .dateCreated)
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let email = try container.decode(String.self, forKey: .email)
        let name = try container.decode(String.self, forKey: .name)
        let roleString = try container.decode(String.self, forKey: .role)
        let role = UserRole(rawValue: roleString) ?? .reader

        self.init(email: email, name: name, role: role)

        self.id = try container.decode(UUID.self, forKey: .id)
        self.birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear)
        let tierString = try container.decode(String.self, forKey: .subscriptionTier)
        self.subscriptionTier = SubscriptionTier(rawValue: tierString) ?? .free
        self.profilePhotoURL = try container.decodeIfPresent(String.self, forKey: .profilePhotoURL)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }
}
