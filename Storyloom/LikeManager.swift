import Foundation

/// Persists liked story UUIDs locally so like state survives across sessions.
/// Acts as the source of truth for whether the current user has liked a given story.
final class LikeManager {

    static let shared = LikeManager()

    /// Key is namespaced by user ID so two accounts on the same device never share like state.
    private var defaultsKey: String {
        let uid = AuthManager.shared.supabaseUserId?.uuidString ?? "anon"
        return "storyloom_liked_\(uid)"
    }

    // In-memory cache — avoids deserializing the UserDefaults plist on every isLiked() call.
    // Keyed by defaultsKey so it auto-invalidates if the logged-in user changes.
    private var _cacheKey: String? = nil
    private var _cache: Set<UUID>? = nil

    private init() {}

    // MARK: - Private cache

    private var cachedSet: Set<UUID> {
        let key = defaultsKey
        if key != _cacheKey || _cache == nil {
            let strings = UserDefaults.standard.stringArray(forKey: key) ?? []
            _cache = Set(strings.compactMap { UUID(uuidString: $0) })
            _cacheKey = key
        }
        return _cache!
    }

    // MARK: - Read

    var likedUUIDs: Set<UUID> {
        get { cachedSet }
        set {
            _cache = newValue
            _cacheKey = defaultsKey
            UserDefaults.standard.set(newValue.map { $0.uuidString }, forKey: defaultsKey)
        }
    }

    func isLiked(_ uuid: UUID) -> Bool {
        cachedSet.contains(uuid)
    }

    // MARK: - Write

    func like(_ uuid: UUID) {
        guard !cachedSet.contains(uuid) else { return } // already liked — no-op
        var uuids = cachedSet
        uuids.insert(uuid)
        likedUUIDs = uuids
    }

    func unlike(_ uuid: UUID) {
        var uuids = cachedSet
        uuids.remove(uuid)
        likedUUIDs = uuids
    }

    // MARK: - Clear (called on logout)

    func clearAll() {
        _cache = nil
        _cacheKey = nil
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }
}
