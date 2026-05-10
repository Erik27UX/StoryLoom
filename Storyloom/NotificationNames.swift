import Foundation

// MARK: - Typed Notification Names
// All app-wide NotificationCenter events are declared here to eliminate stringly-typed
// Notification.Name("...") literals scattered across the codebase.

extension Notification.Name {
    /// Posted when an invite code arrives via a deep link (Universal Link or custom scheme).
    /// userInfo["code"] contains the sanitized 6-character alphanumeric code.
    static let storyloomJoinCode = Notification.Name("storyloom.joinCode")

    /// Posted by RealtimeManager when new activity (comment, question, reaction) is received
    /// for a story the current user has access to.
    static let storyloomNewActivity = Notification.Name("storyloom.newActivity")

    /// Posted by NotificationManager when a push notification tap should navigate to a story.
    /// userInfo["storyId"] contains the target story's UUID.
    static let storyloomOpenStory = Notification.Name("storyloom.openStory")

    /// Posted by RealtimeManager when a question the current reader submitted gets answered.
    /// userInfo["record"] contains the updated question record.
    static let storyloomQuestionAnswered = Notification.Name("storyloom.questionAnswered")
}
