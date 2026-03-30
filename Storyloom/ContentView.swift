import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "FDF9F0"))
        appearance.shadowColor = UIColor(Color(hex: "EAE0C8"))

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color(hex: "A8926A"))
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color(hex: "2E2418"))
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "A8926A"))
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "2E2418"))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                        .font(.system(size: 20))
                    Text("Home")
                }
                .tag(0)

            StoriesLibraryView()
                .tabItem {
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 20))
                    Text("Stories")
                }
                .tag(1)

            FamilyView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 20))
                    Text("Family")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
