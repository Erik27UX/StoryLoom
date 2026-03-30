import SwiftUI
import SwiftData

@main
struct StoryloomApp: App {
    @AppStorage("hasSeededData") private var hasSeededData = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear { seedIfNeeded() }
        }
        .modelContainer(for: StoryEntry.self)
    }

    // Runs once on first launch to populate sample stories
    private func seedIfNeeded() {
        guard !hasSeededData else { return }
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        guard let container = try? ModelContainer(for: StoryEntry.self, configurations: config) else { return }
        SampleData.seedStories(in: container.mainContext)
        hasSeededData = true
    }
}
