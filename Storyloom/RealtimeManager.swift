import Foundation
import Supabase
import Combine
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "erikfischer.Storyloom", category: "Realtime")

// MARK: - RealtimeManager
// Subscribes to Supabase Realtime postgres_changes for comments and questions tables.
// Posts "storyloom.newActivity" notification when a new row is inserted so views can refresh.

@MainActor
final class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()

    private var channel: RealtimeChannelV2?
    /// Set of story UUIDs we are legitimately subscribed to.
    /// Events for any other story_id are silently dropped client-side.
    private var allowedStoryIds: Set<UUID> = []

    private init() {}

    // MARK: - Start Listening

    /// Subscribe to INSERT events on comments and questions for the given story IDs.
    func startListening(storyIds: [UUID]) {
        guard !storyIds.isEmpty else { return }
        stopListening()
        allowedStoryIds = Set(storyIds)

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
                self?.handleInsert(table: "comments", record: change.record)
            }
        }

        // Listen for new questions on user's stories
        newChannel.onPostgresChange(
            InsertAction.self,
            schema: "public",
            table: "questions"
        ) { [weak self] change in
            Task { @MainActor in
                self?.handleInsert(table: "questions", record: change.record)
            }
        }

        Task {
            await newChannel.subscribe()
        }

        channel = newChannel
        logger.debug("subscribed to activity for \(storyIds.count) stories")
    }

    // MARK: - Stop Listening

    func stopListening() {
        guard let ch = channel else { return }
        Task {
            await ch.unsubscribe()
        }
        channel = nil
        allowedStoryIds = []
        logger.debug("unsubscribed from activity channel")
    }

    // MARK: - Handle Incoming Change

    private func handleInsert(table: String, record: [String: AnyJSON]) {
        // Security: drop events for stories we are not subscribed to.
        if let storyIdValue = record["story_id"],
           case .string(let s) = storyIdValue,
           let storyId = UUID(uuidString: s) {
            guard allowedStoryIds.contains(storyId) else {
                logger.debug("dropped event for unsubscribed story")
                return
            }
        }

        logger.debug("new activity received on \(table)")
        // Upsert just this one record into SwiftData — no network round-trip.
        SyncManager.shared.ingestRealtimeRecord(table: table, record: record)
        // Notify views so activity indicators / unread badges can update.
        NotificationCenter.default.post(
            name: .storyloomNewActivity,
            object: nil,
            userInfo: ["record": record]
        )
    }
}
