import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "FDF9F0"))
        appearance.shadowColor = UIColor(Color(hex: "EAE0C8"))

        let normal: [NSAttributedString.Key: Any]   = [.foregroundColor: UIColor(Color(hex: "A8926A"))]
        let selected: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(Color(hex: "2E2418"))]

        appearance.stackedLayoutAppearance.normal.iconColor   = UIColor(Color(hex: "A8926A"))
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "2E2418"))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = normal
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selected

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        if !authManager.isLoggedIn {
            // Not logged in → show LoginView
            NavigationStack {
                LoginView()
            }
        } else if !authManager.hasCompletedOnboarding {
            // Logged in but no onboarding → show Welcome flow
            NavigationStack {
                WelcomeView()
            }
        } else {
            // Fully onboarded → show main app
            mainApp
        }
    }

    @ViewBuilder
    private var mainApp: some View {
        let isStoryteller = authManager.currentUser?.role == .storyteller

        TabView(selection: $selectedTab) {
            if isStoryteller {
                NavigationStack {
                    HomeView()
                }
                .id("home-\(selectedTab)")
                .tabItem { Image(systemName: "house.fill");       Text("Home") }
                .tag(0)

                NavigationStack {
                    StoriesLibraryView()
                }
                .id("stories-\(selectedTab)")
                .tabItem { Image(systemName: "square.stack.fill"); Text("Stories") }
                .tag(1)

                NavigationStack {
                    ReadersView()
                }
                .id("readers-\(selectedTab)")
                .tabItem { Image(systemName: "person.2.fill");    Text("Readers") }
                .tag(2)

                NavigationStack {
                    SettingsView()
                }
                .id("account-\(selectedTab)")
                .tabItem { Image(systemName: "person.circle.fill"); Text("Account") }
                .tag(3)
            } else {
                NavigationStack {
                    ReaderHomeView()
                }
                .id("home-\(selectedTab)")
                .tabItem { Image(systemName: "house.fill");       Text("Home") }
                .tag(0)

                NavigationStack {
                    ReaderStoriesView()
                }
                .id("stories-\(selectedTab)")
                .tabItem { Image(systemName: "square.stack.fill"); Text("Stories") }
                .tag(1)

                NavigationStack {
                    ReaderActivityView()
                }
                .id("activity-\(selectedTab)")
                .tabItem { Image(systemName: "bubble.left.and.bubble.right.fill"); Text("Activity") }
                .tag(2)

                NavigationStack {
                    SettingsView()
                }
                .id("account-\(selectedTab)")
                .tabItem { Image(systemName: "person.circle.fill"); Text("Account") }
                .tag(3)
            }
        }
        .onAppear(perform: seedIfNeeded)
    }

    private func seedIfNeeded() {
        let descriptor = FetchDescriptor<StoryEntry>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        print("📊 Current story count: \(count)")
        guard count == 0 else {
            print("✅ Data already seeded, skipping")
            return
        }
        print("🌱 Seeding data...")
        SampleData.seedStories(in: modelContext)
        print("✅ Seeding complete")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    SampleData.seedStories(in: container.mainContext)

    // Mock logged-in user for preview
    let authManager = AuthManager.shared
    let mockUser = User(email: "preview@test.com", name: "Preview User", role: .storyteller)
    authManager.currentUser = mockUser
    authManager.isLoggedIn = true
    authManager.hasCompletedOnboarding = true

    return ContentView()
        .modelContainer(container)
        .environmentObject(authManager)
}
