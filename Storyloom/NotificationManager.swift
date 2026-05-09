import SwiftUI
import Combine
import UserNotifications
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "erikfischer.Storyloom", category: "Notifications")

// MARK: - Notification Category Identifiers

enum NotificationCategory: String {
    /// A new story was published to a vault the reader has access to.
    case newStory      = "NEW_STORY"
    /// A reader's question was answered by the storyteller.
    case questionAnswered = "QUESTION_ANSWERED"
    /// A new comment was posted on a story the storyteller owns.
    case newComment    = "NEW_COMMENT"
}

// MARK: - Notification User Info Keys

enum NotificationKey {
    static let category  = "category"
    static let storyId   = "story_id"
    static let questionId = "question_id"
}

// MARK: - NotificationManager
// Centralizes all push-notification logic: permission requests, token registration,
// foreground presentation, and tap-action routing.
//
// How to activate once enrolled in Apple Developer Program:
// 1. Enable Push Notifications capability in Xcode → Signing & Capabilities.
// 2. Add the Push Notifications entitlement.
// 3. Call NotificationManager.shared.requestPermission() from ContentView.onAppear.
// 4. Wire `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` in
//    AppDelegate (or use the SwiftUI scene phase approach below).
// 5. Create a Supabase edge function to send notifications via APNs, triggered by
//    DB webhooks on insert into stories / questions / comments tables.

@MainActor
final class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var deviceToken: String? = nil

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Setup (call once on app launch)

    func setup() {
        Task { await refreshAuthorizationStatus() }
        registerNotificationCategories()
    }

    // MARK: - Permission

    /// Requests push notification permission. Safe to call multiple times.
    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            if granted {
                await registerForRemoteNotifications()
            }
            logger.debug("notification permission granted: \(granted)")
        } catch {
            logger.error("notification permission request failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    // MARK: - Token Registration

    /// Registers with APNs. Must be called after permission is granted.
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    /// Called by StoryloomApp when APNs issues a device token.
    func didRegisterForRemoteNotifications(deviceToken data: Data) {
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        logger.debug("APNs device token registered")
        Task { await uploadTokenToSupabase(token) }
    }

    /// Called by StoryloomApp when APNs token registration fails.
    func didFailToRegisterForRemoteNotifications(error: Error) {
        logger.error("APNs token registration failed: \(error.localizedDescription, privacy: .private)")
    }

    // MARK: - Supabase Token Upload

    /// Stores the push token on the user's profile row so the server can target this device.
    ///
    /// Requires a `push_token text` column on the `profiles` table and an RLS UPDATE policy
    /// allowing users to update their own profile. Migration:
    ///   ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS push_token text;
    private func uploadTokenToSupabase(_ token: String) async {
        guard let userId = AuthManager.shared.supabaseUserId else { return }
        do {
            struct TokenUpdate: Encodable { let push_token: String }
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(TokenUpdate(push_token: token))
                .eq("id", value: userId.uuidString)
                .execute()
            logger.debug("push token uploaded to Supabase")
        } catch {
            logger.error("push token upload failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    // MARK: - Notification Categories

    /// Registers actionable notification categories with the OS.
    private func registerNotificationCategories() {
        let newStoryCategory = UNNotificationCategory(
            identifier: NotificationCategory.newStory.rawValue,
            actions: [],
            intentIdentifiers: []
        )
        let questionAnsweredCategory = UNNotificationCategory(
            identifier: NotificationCategory.questionAnswered.rawValue,
            actions: [],
            intentIdentifiers: []
        )
        let newCommentCategory = UNNotificationCategory(
            identifier: NotificationCategory.newComment.rawValue,
            actions: [],
            intentIdentifiers: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            newStoryCategory,
            questionAnsweredCategory,
            newCommentCategory,
        ])
    }

    // MARK: - Status Refresh

    private func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Tap Routing

    /// Inspects a notification's userInfo and posts the appropriate in-app navigation event.
    private func routeNotification(_ userInfo: [AnyHashable: Any]) {
        guard let categoryRaw = userInfo[NotificationKey.category] as? String,
              let category = NotificationCategory(rawValue: categoryRaw) else { return }

        switch category {
        case .newStory, .newComment:
            if let storyIdStr = userInfo[NotificationKey.storyId] as? String,
               let storyId = UUID(uuidString: storyIdStr) {
                NotificationCenter.default.post(
                    name: .storyloomOpenStory,
                    object: nil,
                    userInfo: ["storyId": storyId]
                )
            }

        case .questionAnswered:
            if let storyIdStr = userInfo[NotificationKey.storyId] as? String,
               let storyId = UUID(uuidString: storyIdStr) {
                NotificationCenter.default.post(
                    name: .storyloomOpenStory,
                    object: nil,
                    userInfo: ["storyId": storyId]
                )
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Show notification banners even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// User tapped a notification — route to the relevant screen.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            self.routeNotification(userInfo)
        }
        completionHandler()
    }
}
