import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var coordinator = AppCoordinator.shared
    @Environment(\.modelContext) private var modelContext
    @State private var tabIds: [Int: UUID] = [0: UUID(), 1: UUID(), 2: UUID(), 3: UUID()]

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.992, green: 0.976, blue: 0.941, alpha: 1.0) // FDF9F0
        appearance.shadowColor = UIColor(red: 0.918, green: 0.878, blue: 0.784, alpha: 1.0) // EAE0C8

        let normalColor = UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1.0) // 1C1917 - dark
        let selectedColor = UIColor(red: 0.18, green: 0.14, blue: 0.09, alpha: 1.0) // 2E2418 - dark brown

        let normal: [NSAttributedString.Key: Any]   = [.foregroundColor: normalColor]
        let selected: [NSAttributedString.Key: Any] = [.foregroundColor: selectedColor]

        appearance.stackedLayoutAppearance.normal.iconColor   = normalColor
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes   = normal
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selected

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Navigation bar — force dark text on the cream background for all large/inline titles
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(red: 0.992, green: 0.976, blue: 0.941, alpha: 1.0)
        let titleColor = UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1.0)
        navAppearance.titleTextAttributes = [.foregroundColor: titleColor]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance
    }

    var body: some View {
        if authManager.isCheckingAuth {
            // Checking for an existing session — show splash to avoid login flash
            splashView
        } else if !authManager.isLoggedIn {
            // No session found — show login
            NavigationStack {
                LoginView()
            }
        } else if authManager.currentUser?.subscriptionTier == .free && !authManager.hasCompletedOnboarding {
            // Free users need to complete onboarding to access the app
            NavigationStack {
                WelcomeView()
            }
        } else {
            // Fully authenticated: premium/legend users skip onboarding, free users already onboarded
            mainApp
        }
    }

    // MARK: - Splash Screen

    private var splashView: some View {
        ZStack {
            SL.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(SL.accent)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: SL.accent))
            }
        }
    }

    // MARK: - Main App

    @ViewBuilder
    private var mainApp: some View {
        let isStoryteller = authManager.currentUserRole == .storyteller

        TabView(selection: $coordinator.selectedTab) {
            if isStoryteller {
                NavigationStack {
                    HomeView()
                }
                .id(tabIds[0])
                .tabItem { Image(systemName: "house.fill");       Text("Home") }
                .tag(0)

                StoriesLibraryView()
                .id(tabIds[1])
                .tabItem { Image(systemName: "square.stack.fill"); Text("Stories") }
                .tag(1)

                NavigationStack {
                    ReadersView()
                }
                .id(tabIds[2])
                .tabItem { Image(systemName: "person.2.fill");    Text("Readers") }
                .tag(2)

                NavigationStack {
                    SettingsView()
                }
                .id(tabIds[3])
                .tabItem { Image(systemName: "person.circle.fill"); Text("Account") }
                .tag(3)
            } else {
                NavigationStack {
                    ReaderHomeView(selectedTab: $coordinator.selectedTab)
                }
                .id(tabIds[0])
                .tabItem { Image(systemName: "house.fill");       Text("Home") }
                .tag(0)

                NavigationStack {
                    ReaderStoriesView()
                }
                .id(tabIds[1])
                .tabItem { Image(systemName: "square.stack.fill"); Text("Stories") }
                .tag(1)

                NavigationStack {
                    ReaderActivityView()
                }
                .id(tabIds[2])
                .tabItem { Image(systemName: "bubble.left.and.bubble.right.fill"); Text("Activity") }
                .tag(2)

                NavigationStack {
                    SettingsView()
                }
                .id(tabIds[3])
                .tabItem { Image(systemName: "person.circle.fill"); Text("Account") }
                .tag(3)
            }
        }
        .onChange(of: coordinator.selectedTab) { oldTab, newTab in
            // Delay reset until after tab-switch animation to avoid black flash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                tabIds[oldTab] = UUID()
            }
        }
        .onChange(of: coordinator.tabToReset) { _, tabIdx in
            // Programmatic nav-stack reset (e.g. "Close" from a confirmation modal)
            guard let idx = tabIdx else { return }
            tabIds[idx] = UUID()
            DispatchQueue.main.async { coordinator.tabToReset = nil }
        }
        .onAppear(perform: seedIfNeeded)
    }

    // MARK: - Sample Data Seeding (dev / first-launch only)

    private func seedIfNeeded() {
        #if DEBUG
        let descriptor = FetchDescriptor<StoryEntry>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        SampleData.seedStories(in: modelContext)
        #endif
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    SampleData.seedStories(in: container.mainContext)

    let authManager = AuthManager.shared
    let mockUser = User(email: "preview@test.com", name: "Preview User", role: .storyteller)
    authManager.currentUser = mockUser
    authManager.isLoggedIn = true
    authManager.hasCompletedOnboarding = true
    authManager.isCheckingAuth = false

    return ContentView()
        .modelContainer(container)
        .environmentObject(authManager)
}
