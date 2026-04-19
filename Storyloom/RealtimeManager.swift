import Foundation
import Supabase
import Combine

// MARK: - RealtimeManager
// Subscribes to Supabase Realtime postgres_changes for comments and questions tables.
// Posts "storyloom.newActivity" notification when a new row is inserted so views can refresh.

@MainActor
final class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()

    private var channel: RealtimeChannelV2?

    private init() {}

    // MARK: - Start Listening

    /// Subscribe to INSERT events on comments and questions for the given story IDs.
    func startListening(storyIds: [UUID]) {
        guard !storyIds.isEmpty else { return }
        stopListening()

        let client = SupabaseManager.shared.client
        let channelName = "storyloom_activity_\(UUID().uuidString.prefix(8))"

        let newChannel = client.realtimeV2.channel(channelName)

        // Listen for new comments on user's stories
        newChannel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "comments"
        ) { [weak self] change in
            Task { @MainActor in
                self?.handleNewActivity(change.record)
            }
        }

        // Listen for new questions on user's stories
        newChannel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "questions"
        ) { [weak self] change in
            Task { @MainActor in
                self?.handleNewActivity(change.record)
            }
        }

        Task {
            await newChannel.subscribe()
        }

        channel = newChannel
        print("RealtimeManager: subscribed to activity for \(storyIds.count) stories")
    }

    // MARK: - Stop Listening

    func stopListening() {
        guard let ch = channel else { return }
        Task {
            await ch.unsubscribe()
        }
        channel = nil
        print("RealtimeManager: unsubscribed from activity channel")
    }

    // MARK: - Handle Incoming Change

    private func handleNewActivity(_ record: [String: AnyJSON]) {
        print("RealtimeManager: new activity received")
        NotificationCenter.default.post(
            name: Notification.Name("storyloom.newActivity"),
            object: nil,
            userInfo: ["record": record]
        )
        // Also trigger a full sync pull so SwiftData reflects the latest data
        SyncManager.shared.pullAllUserData()
    }
}
