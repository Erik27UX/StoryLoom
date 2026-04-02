import SwiftUI
import SwiftData

@main
struct StoryloomApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [StoryEntry.self, Folder.self])
    }
}
