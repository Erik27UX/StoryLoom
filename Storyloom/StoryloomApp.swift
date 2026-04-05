import SwiftUI
import SwiftData

@main
struct StoryloomApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: StoryEntry.self, Folder.self, StoryComment.self, StoryQuestion.self
            )
            // Give SyncManager access to the SwiftData main context
            SyncManager.shared.configure(with: modelContainer.mainContext)
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
