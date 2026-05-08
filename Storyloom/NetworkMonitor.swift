import Combine
import Network
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "erikfischer.Storyloom", category: "Network")

// MARK: - NetworkMonitor
// Observes NWPathMonitor and publishes connectivity changes on the main actor.
// Views observe `isConnected` to show an offline banner.

@MainActor
final class NetworkMonitor: ObservableObject {

    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "erikfischer.Storyloom.NetworkMonitor", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isConnected != connected {
                    self.isConnected = connected
                    logger.debug("connectivity changed: \(connected ? "online" : "offline")")
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
