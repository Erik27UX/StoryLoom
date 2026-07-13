import SwiftUI
import Combine

/// Drives the app-wide "Large Text" accessibility toggle in Settings.
/// SL's font helpers read `scale` directly; ContentView observes this object
/// so toggling it re-renders the whole tree with the new sizes.
final class TextSizeManager: ObservableObject {
    static let shared = TextSizeManager()

    private static let key = "isLargeTextEnabled"

    @Published var isLarge: Bool {
        didSet { UserDefaults.standard.set(isLarge, forKey: Self.key) }
    }

    var scale: CGFloat { isLarge ? 1.12 : 1.0 }

    private init() {
        isLarge = UserDefaults.standard.bool(forKey: Self.key)
    }
}
