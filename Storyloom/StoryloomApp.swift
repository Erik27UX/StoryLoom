import SwiftUI
import SwiftData
import Supabase

@main
struct StoryloomApp: App {
    let modelContainer: ModelContainer

    init() {
        print("StoryloomApp: init starting...")
        do {
            print("StoryloomApp: creating ModelContainer...")
            modelContainer = try ModelContainer(
                for: StoryEntry.self, Folder.self, StoryComment.self, StoryQuestion.self,
                    StoryAccess.self, StoryInvite.self
            )
            print("StoryloomApp: configuring SyncManager...")
            // Give SyncManager access to the SwiftData main context
            SyncManager.shared.configure(with: modelContainer.mainContext)
            print("StoryloomApp: init complete")
        } catch {
            print("StoryloomApp: FATAL ERROR - \(error)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        print("StoryloomApp: received deep link: \(url)")

        guard url.scheme == "storyloom" else { return }

        // Handle invite join links: storyloom://join/CODE
        if url.host == "join" {
            let code = url.pathComponents.dropFirst().first ?? url.lastPathComponent
            if !code.isEmpty {
                print("StoryloomApp: invite code deep link received: \(code)")
                NotificationCenter.default.post(
                    name: Notification.Name("storyloom.joinCode"),
                    object: nil,
                    userInfo: ["code": code]
                )
            }
            return
        }

        // Handle auth callbacks: storyloom://auth/...
        guard url.host == "auth" else { return }

        print("StoryloomApp: processing auth callback")
        Task {
            do {
                // session(from:) handles both PKCE code exchange and implicit token extraction
                try await SupabaseManager.shared.client.auth.session(from: url)
                print("StoryloomApp: session established from deep link")
            } catch {
                print("StoryloomApp: deep link session failed: \(error)")
            }
        }
    }
}
