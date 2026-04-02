import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("userRole") private var userRole = UserRole.storyteller.rawValue
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

    var isStoryteller: Bool { userRole == UserRole.storyteller.rawValue }

    var body: some View {
        TabView(selection: $selectedTab) {
            if isStoryteller {
                HomeView()
                    .tabItem { Image(systemName: "house.fill");       Text("Home") }
                    .tag(0)
                StoriesLibraryView()
                    .tabItem { Image(systemName: "square.stack.fill"); Text("Stories") }
                    .tag(1)
                ReadersView()
                    .tabItem { Image(systemName: "person.2.fill");    Text("Readers") }
                    .tag(2)
                AccountView()
                    .tabItem { Image(systemName: "person.circle.fill"); Text("Account") }
                    .tag(3)
            } else {
                ReaderHomeView()
                    .tabItem { Image(systemName: "house.fill");       Text("Home") }
                    .tag(0)
                ReaderStoriesView()
                    .tabItem { Image(systemName: "square.stack.fill"); Text("Stories") }
                    .tag(1)
                ReaderActivityView()
                    .tabItem { Image(systemName: "bubble.left.and.bubble.right.fill"); Text("Activity") }
                    .tag(2)
                AccountView()
                    .tabItem { Image(systemName: "person.circle.fill"); Text("Account") }
                    .tag(3)
            }
        }
        .onAppear(perform: seedIfNeeded)
    }

    // Seeds two sample stories on first launch.
    // Uses story count (not a flag) so it's safe even if AppStorage was corrupted.
    private func seedIfNeeded() {
        let descriptor = FetchDescriptor<StoryEntry>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }
        SampleData.seedStories(in: modelContext)
    }
}

#Preview {
    ContentView()
}
