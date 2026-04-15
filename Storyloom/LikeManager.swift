import Foundation

/// Persists liked story UUIDs locally so like state survives across sessions.
/// Acts as the source of truth for whether the current user has liked a given story.
final class LikeManager {

    static let shared = LikeManager()

    private let defaultsKey = "storyloom_liked_story_uuids"

    private init() {}

    // MARK: - Read

    var likedUUIDs: Set<UUID> {
        get {
            let strings = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
            return Set(strings.compactMap { UUID(uuidString: $0) })
        }
        set {
            UserDefaults.standard.set(newValue.map { $0.uuidString }, forKey: defaultsKey)
        }
    }

    func isLiked(_ uuid: UUID) -> Bool {
        likedUUIDs.contains(uuid)
    }

    // MARK: - Write

    func like(_ uuid: UUID) {
        var uuids = likedUUIDs
        guard !uuids.contains(uuid) else { return } // already liked — no-op
        uuids.insert(uuid)
        likedUUIDs = uuids
    }

    func unlike(_ uuid: UUID) {
        var uuids = likedUUIDs
        uuids.remove(uuid)
        likedUUIDs = uuids
    }

    // MARK: - Clear (called on logout)

    func clearAll() {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
