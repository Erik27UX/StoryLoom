import SwiftUI
import SwiftData

struct StoriesLibraryView: View {
    @Query(sort: \StoryEntry.dateCreated, order: .reverse) private var allStories: [StoryEntry]
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]
    @StateObject private var coordinator = AppCoordinator.shared
    @ObservedObject var authManager = AuthManager.shared
    @State private var sortBy: SortOption = .created
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""
    /// Debounced copy — updated 250 ms after the user stops typing.
    /// Using this in groupedStories prevents an O(n) full-content scan on every keystroke.
    @State private var debouncedSearch = ""

    private var groupedStories: [(folder: Folder?, stories: [StoryEntry])] {
        // Filter stories based on sort option
        let sortFiltered: [StoryEntry]
        switch sortBy {
        case .published:
            sortFiltered = allStories.filter { $0.isInVault }
        case .draft:
            sortFiltered = allStories.filter { !$0.isInVault }
        default:
            sortFiltered = allStories
        }

        // Apply search filter against the debounced text so full-content
        // scans only run after the user pauses typing, not on every keystroke.
        let filtered = debouncedSearch.isEmpty ? sortFiltered : sortFiltered.filter { story in
            story.title.localizedCaseInsensitiveContains(debouncedSearch) ||
            story.content.localizedCaseInsensitiveContains(debouncedSearch)
        }

        // Year sort: flatten all folders into one chronological list so sorting
        // works across the entire library, not just within each folder bucket.
        if sortBy == .year {
            let sorted = filtered.sorted { ($0.year ?? 0) < ($1.year ?? 0) }
            return [(folder: nil, stories: sorted)]
        }

        // Create a dictionary grouped by folder
        var grouped: [UUID?: [StoryEntry]] = [:]

        for story in filtered {
            let key = story.folder?.id
            if grouped[key] == nil {
                grouped[key] = []
            }
            grouped[key]?.append(story)
        }

        // Sort stories within each group
        for key in grouped.keys {
            grouped[key]?.sort { lhs, rhs in
                switch sortBy {
                case .created:
                    return lhs.dateCreated > rhs.dateCreated
                case .draft, .published:
                    return lhs.dateCreated > rhs.dateCreated
                case .year:
                    return (lhs.year ?? 0) < (rhs.year ?? 0) // unreachable — handled above
                }
            }
        }

        // Create result array with folder objects
        var result: [(folder: Folder?, stories: [StoryEntry])] = []

        // Add folders with stories first
        for folder in folders {
            if let stories = grouped[folder.id], !stories.isEmpty {
                result.append((folder, stories))
            }
        }

        // Add unfiled stories at the end
        if let unfiledStories = grouped[nil], !unfiledStories.isEmpty {
            result.append((nil, unfiledStories))
        }

        return result
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 12) {
                        Text("Your stories")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)

                        Spacer()

                        // Sort toggle
                        Menu {
                            Button(action: { sortBy = .created }) {
                                HStack {
                                    Text("Newest First")
                                    Spacer()
                                    if sortBy == .created {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: { sortBy = .year }) {
                                HStack {
                                    Text("Story Year")
                                    Spacer()
                                    if sortBy == .year {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Divider()
                            Button(action: { sortBy = .published }) {
                                HStack {
                                    Text("Published")
                                    Spacer()
                                    if sortBy == .published {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: { sortBy = .draft }) {
                                HStack {
                                    Text("Draft")
                                    Spacer()
                                    if sortBy == .draft {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SL.accent)
                                .padding(8)
                                .background(SL.surface)
                                .clipShape(Circle())
                        }

                        // Manage folders button
                        NavigationLink(destination: FolderManagerView()) {
                            Image(systemName: "folder.badge.gear")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SL.accent)
                                .padding(8)
                                .background(SL.surface)
                                .clipShape(Circle())
                        }
                    }

                    if allStories.isEmpty {
                        LibraryEmptyState()
                    } else {
                        // Display grouped stories
                        ForEach(groupedStories, id: \.folder?.id) { folder, stories in
                            VStack(alignment: .leading, spacing: 12) {
                                // Folder header — suppressed when year sort flattens everything
                                if sortBy != .year {
                                    Text(folder?.name ?? "Unfiled")
                                        .font(.system(size: 13, weight: .semibold))
                                        .tracking(1)
                                        .textCase(.uppercase)
                                        .foregroundColor(SL.textSecondary)
                                }

                                // Stories in folder
                                ForEach(stories) { story in
                                    NavigationLink(value: story.uuid) {
                                        StoryLibraryCard(story: story)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Locked upgrade card — only shown to free users
                    if authManager.currentUser?.subscriptionTier == .free {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SL.primary)
                                .frame(width: 44, height: 44)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "FDF9F0"))
                        }

                        Text("More stories waiting")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(SL.textPrimary)

                        Text("Upgrade to unlock and share with family")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)

                        NavigationLink(destination: UpgradeView()) {
                            Text("View Plans")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(SL.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(SL.surface.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )
                    } // end if free
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await SyncManager.shared.pullAllUserDataAsync()
            }
            .background(SL.background)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stories")
            // Debounce: update debouncedSearch 250 ms after the user stops typing.
            // .task(id:) cancels the previous sleep automatically on each new keystroke.
            .task(id: searchText) {
                if searchText.isEmpty { debouncedSearch = ""; return }
                try? await Task.sleep(for: .milliseconds(250))
                debouncedSearch = searchText
            }
            .toolbarBackground(SL.background, for: .navigationBar)
            .navigationDestination(for: UUID.self) { storyId in
                if let story = allStories.first(where: { $0.uuid == storyId }) {
                    StoryDetailView(story: story)
                } else {
                    ContentUnavailableView("Story not found", systemImage: "book.closed")
                }
            }
        }
        .onChange(of: coordinator.storyToOpen) { _, storyId in
            guard let id = storyId else { return }
            navigationPath.removeLast(navigationPath.count)
            navigationPath.append(id)
            DispatchQueue.main.async { coordinator.storyToOpen = nil }
        }
    }
}

struct StoryLibraryCard: View {
    let story: StoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Story image — only shown when story has an image
            if story.imageFileName != nil {
                StoryImageView(story: story)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(alignment: .top) {
                Text(story.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SL.textPrimary)
                    .lineLimit(2)
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if story.isInVault {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(SL.textAccent)
                            Text("Published")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(SL.textPrimary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SL.accent.opacity(0.1))
                        .clipShape(Capsule())
                    } else {
                        Text("Private")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SL.border.opacity(0.5))
                            .clipShape(Capsule())
                    }
                    if let year = story.year {
                        Text(formatYear(year))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SL.surface.opacity(0.8))
                            .clipShape(Capsule())
                    }
                }
            }

            Text(story.preview)
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .lineLimit(2)

            HStack {
                Text(story.dateFormatted)
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
                Spacer()
                if story.likeCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "C17B6A"))
                        Text("\(story.likeCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                    }
                }
            }
        }
        .padding(18)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SL.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }

    private func formatYear(_ year: Int) -> String {
        String(year)
    }
}

struct LibraryEmptyState: View {
    private let steps: [(icon: String, text: String)] = [
        ("questionmark.circle", "Answer a prompt on the Home tab"),
        ("lock.open",           "Publish it to your vault"),
        ("person.2",            "Share your invite code with family"),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(SL.accent.opacity(0.1))
                        .frame(width: 72, height: 72)
                    Image(systemName: "pencil.and.list.clipboard")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(SL.accent)
                }

                Text("Your first story is waiting")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(SL.textPrimary)

                Text("Every family story starts somewhere. Here's how it works:")
                    .font(SL.body(14))
                    .foregroundColor(SL.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SL.accent.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(SL.accent)
                        }
                        Text(step.text)
                            .font(SL.body(14))
                            .foregroundColor(SL.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SL.accent.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SL.border, lineWidth: 1))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    SampleData.seedStories(in: container.mainContext)
    return NavigationStack {
        StoriesLibraryView()
    }
    .modelContainer(container)
}
