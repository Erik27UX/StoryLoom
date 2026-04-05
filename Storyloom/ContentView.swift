import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var tabIds: [Int: UUID] = [0: UUID(), 1: UUID(), 2: UUID(), 3: UUID()]

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
        if authManager.isCheckingAuth {
            // Checking for an existing session — show splash to avoid login flash
            splashView
        } else if !authManager.isLoggedIn {
            // No session found — show login
            NavigationStack {
                LoginView()
            }
        } else if !authManager.hasCompletedOnboarding {
            // Logged in but onboarding not done — show welcome flow
            NavigationStack {
                WelcomeView()
            }
        } else {
            // Fully authenticated and onboarded
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
        let isStoryteller = authManager.currentUser?.role == .storyteller

        TabView(selection: $selectedTab) {
            if isStoryteller {
                NavigationStack {
                    HomeView()
                }
                .id(tabIds[0])
                .tabItem { Image(systemName: "house.fill");       Text("Home") }
                .tag(0)

                NavigationStack {
                    StoriesLibraryView()
                }
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
                    ReaderHomeView()
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
        .onChange(of: selectedTab) { oldTab, newTab in
            // Delay reset until after tab-switch animation to avoid black flash
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                tabIds[oldTab] = UUID()
            }
        }
        .onAppear(perform: seedIfNeeded)
    }

    // MARK: - Sample Data Seeding (dev / first-launch only)

    private func seedIfNeeded() {
        let descriptor = FetchDescriptor<StoryEntry>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        SampleData.seedStories(in: modelContext)
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
