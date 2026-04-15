import SwiftUI
import Combine

// MARK: - AppCoordinator
// Central coordinator for cross-tab navigation. Views can use this singleton
// to switch tabs and programmatically open specific stories.

final class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()

    /// Currently selected tab index (0=Home, 1=Stories, 2=Activity/Readers, 3=Account)
    @Published var selectedTab: Int = 0

    /// When set, StoriesLibraryView will push to this story UUID.
    /// Cleared immediately after navigation.
    @Published var storyToOpen: UUID? = nil

    /// When set, ContentView will reset the navigation stack for this tab index.
    /// Cleared immediately after reset.
    @Published var tabToReset: Int? = nil

    private init() {}

    /// Switch to the Stories tab and open the story with the given UUID.
    func navigateToStory(_ storyId: UUID) {
        selectedTab = 1
        // Delay so the tab-switch animation completes before pushing to nav stack
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.storyToOpen = storyId
        }
    }

    /// Reset the Home tab navigation stack and switch to Home.
    /// Handles "Close" from any confirmation modal.
    func returnToHome() {
        tabToReset = 0
        selectedTab = 0
    }
}
