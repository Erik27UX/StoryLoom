import SwiftUI

struct ContentView: View {
    @AppStorage("userRole") private var userRole = UserRole.storyteller.rawValue
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "FDF9F0"))
        appearance.shadowColor = UIColor(Color(hex: "EAE0C8"))

        let normal: [NSAttributedString.Key: Any]   = [.foregroundColor: UIColor(Color(hex: "A8926A"))]
        let selected: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(Color(hex: "2E2418"))]

        appearance.stackedLayoutAppearance.normal.iconColor  = UIColor(Color(hex: "A8926A"))
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "2E2418"))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes  = normal
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selected

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var isStoryteller: Bool { userRole == UserRole.storyteller.rawValue }

    var body: some View {
        TabView(selection: $selectedTab) {
            if isStoryteller {
                // MARK: Storyteller tabs
                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                StoriesLibraryView()
                    .tabItem {
                        Image(systemName: "square.stack.fill")
                        Text("Stories")
                    }
                    .tag(1)

                ReadersView()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Readers")
                    }
                    .tag(2)

                AccountView()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Account")
                    }
                    .tag(3)
            } else {
                // MARK: Reader tabs — stories + activity only, no storyteller tools
                ReaderHomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                ReaderStoriesView()
                    .tabItem {
                        Image(systemName: "square.stack.fill")
                        Text("Stories")
                    }
                    .tag(1)

                ReaderActivityView()
                    .tabItem {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Activity")
                    }
                    .tag(2)

                AccountView()
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Account")
                    }
                    .tag(3)
            }
        }
    }
}

#Preview {
    ContentView()
}
