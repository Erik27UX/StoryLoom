import SwiftUI
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "erikfischer.Storyloom", category: "App")

// MARK: - AppDelegate (APNs token callbacks)

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { await NotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { await NotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error) }
    }
}

// MARK: - App

@main
struct StoryloomApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let modelContainer: ModelContainer

    init() {
        logger.debug("init starting...")
        do {
            logger.debug("creating ModelContainer...")
            modelContainer = try ModelContainer(
                for: StoryEntry.self, Folder.self, StoryComment.self, StoryQuestion.self,
                    StoryAccess.self, StoryInvite.self, StoryReaction.self
            )
            logger.debug("configuring SyncManager...")
            // Give SyncManager access to the SwiftData main context
            SyncManager.shared.configure(with: modelContainer.mainContext)
            // Set up push notification categories and delegate
            Task { await NotificationManager.shared.setup() }
            logger.debug("init complete")
        } catch {
            logger.critical("FATAL: ModelContainer init failed: \(error.localizedDescription, privacy: .private)")
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

    /// Sanitizes a raw invite code from a URL, keeping only uppercase alphanumeric characters
    /// and capping at 6. This prevents injection of arbitrary strings via deep links.
    private func sanitizeInviteCode(_ raw: String) -> String {
        String(raw.uppercased()
            .filter { $0.isLetter || $0.isNumber }
            .prefix(6))
    }

    private func handleDeepLink(_ url: URL) {
        logger.debug("received deep link scheme: \(url.scheme ?? "unknown")")

        // Handle Universal Links: https://storyloom.live/join/CODE
        if url.scheme == "https" && url.host == "storyloom.live" {
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            if pathComponents.first == "join", let raw = pathComponents.dropFirst().first, !raw.isEmpty {
                let code = sanitizeInviteCode(raw)
                guard !code.isEmpty else { return }
                logger.debug("Universal Link invite code received")
                NotificationCenter.default.post(
                    name: .storyloomJoinCode,
                    object: nil,
                    userInfo: ["code": code]
                )
            }
            return
        }

        guard url.scheme == "storyloom" else { return }

        // Handle invite join links: storyloom://join/CODE (fallback custom scheme)
        if url.host == "join" {
            let raw = url.pathComponents.dropFirst().first ?? url.lastPathComponent
            if !raw.isEmpty {
                let code = sanitizeInviteCode(raw)
                guard !code.isEmpty else { return }
                logger.debug("invite code deep link received")
                NotificationCenter.default.post(
                    name: .storyloomJoinCode,
                    object: nil,
                    userInfo: ["code": code]
                )
            }
            return
        }

        // Handle auth callbacks: storyloom://auth/...
        guard url.host == "auth" else { return }

        logger.debug("processing auth callback")
        Task {
            do {
                // session(from:) handles both PKCE code exchange and implicit token extraction
                try await SupabaseManager.shared.client.auth.session(from: url)
                logger.debug("session established from deep link")
            } catch {
                logger.error("deep link session failed: \(error.localizedDescription, privacy: .private)")
            }
        }
    }
}
