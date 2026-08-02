import SwiftUI
import SwiftData

struct ReaderStoriesView: View {
    @Query private var stories: [StoryEntry]
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]
    @StateObject private var coordinator = AppCoordinator.shared
    @State private var navigationPath = NavigationPath()
    /// The single storyteller currently being viewed. Readers browse one
    /// storyteller at a time — there is no combined "All" feed, so a story's
    /// author is always unambiguous. Persisted so the tab reopens where they left off.
    @AppStorage("reader.lastViewedAuthor") private var selectedAuthor: String = ""
    /// Selected category chip. nil = All; `CategoryFilterChips.unfiledID` = no folder.
    @State private var selectedFolderID: UUID?
    @State private var sortBy: SortOption = .created
    @State private var showAddVault = false
    @State private var searchText = ""
    /// Debounced copy — updated 250 ms after the user stops typing.
    @State private var debouncedSearch = ""

    var uniqueAuthors: [String] {
        let authors = stories.filter { $0.isInVault }.map { $0.authorName ?? "Your Stories" }
        return Array(Set(authors)).sorted()
    }

    /// The author actually being shown — falls back to the first available one
    /// if the stored choice is empty or that storyteller is no longer followed.
    var activeAuthor: String? {
        if !selectedAuthor.isEmpty, uniqueAuthors.contains(selectedAuthor) { return selectedAuthor }
        return uniqueAuthors.first
    }

    /// Folders that actually contain visible stories from the active storyteller.
    /// Readers share one local folder table with every vault they've joined, so
    /// the chips must be scoped to the storyteller currently being viewed.
    var authorFolders: [Folder] {
        let ids = Set(authorStories.compactMap { $0.folder?.id })
        return folders.filter { ids.contains($0.id) }
    }

    /// Published stories belonging to the active storyteller, before search/category filters.
    private var authorStories: [StoryEntry] {
        guard let activeAuthor else { return [] }
        return stories.filter { $0.isInVault && ($0.authorName ?? "Your Stories") == activeAuthor }
    }

    private var filteredStories: [StoryEntry] {
        let searched = debouncedSearch.isEmpty ? authorStories : authorStories.filter { story in
            story.title.localizedCaseInsensitiveContains(debouncedSearch) ||
            story.content.localizedCaseInsensitiveContains(debouncedSearch)
        }

        guard let selectedFolderID else { return searched }
        if selectedFolderID == CategoryFilterChips.unfiledID {
            return searched.filter { $0.folder == nil }
        }
        return searched.filter { $0.folder?.id == selectedFolderID }
    }

    /// "Newest first" and "Story year" are flat chronological orders — folder
    /// grouping is deliberately ignored for them, otherwise the ordering would
    /// only apply within each folder bucket rather than across the whole list.
    private var isFlatSort: Bool {
        sortBy == .created || sortBy == .year
    }

    var groupedFilteredStories: [(folder: Folder?, stories: [StoryEntry])] {
        let filtered = filteredStories

        if isFlatSort {
            let sorted: [StoryEntry]
            switch sortBy {
            case .year:
                sorted = filtered.sorted { ($0.year ?? 0) < ($1.year ?? 0) }
            default:
                sorted = filtered.sorted { $0.dateCreated > $1.dateCreated }
            }
            return [(folder: nil, stories: sorted)]
        }

        var grouped: [UUID?: [StoryEntry]] = [:]
        for story in filtered {
            let key = story.folder?.id
            if grouped[key] == nil { grouped[key] = [] }
            grouped[key]?.append(story)
        }
        for key in grouped.keys {
            grouped[key]?.sort { $0.dateCreated > $1.dateCreated }
        }

        var result: [(folder: Folder?, stories: [StoryEntry])] = []
        for folder in folders {
            if let folderStories = grouped[folder.id], !folderStories.isEmpty {
                result.append((folder, folderStories))
            }
        }
        if let unfiledStories = grouped[nil], !unfiledStories.isEmpty {
            result.append((nil, unfiledStories))
        }
        return result
    }

    var showAuthorFilter: Bool {
        uniqueAuthors.count >= 2
    }

    var body: some View {
        let groups = groupedFilteredStories
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Stories")
                                .font(SL.heading(28))
                                .foregroundColor(SL.textPrimary)
                            Text("Shared with you")
                                .font(SL.body(15))
                                .foregroundColor(SL.textSecondary)
                        }
                        Spacer()
                        Button(action: { showAddVault = true }) {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Add Story Vault")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(SL.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(SL.surface)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(SL.border, lineWidth: 1))
                        }
                        Menu {
                            Button(action: { sortBy = .created }) {
                                HStack {
                                    Text("Newest First")
                                    if sortBy == .created {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: { sortBy = .year }) {
                                HStack {
                                    Text("Story Year")
                                    if sortBy == .year {
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
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                    // Storyteller picker (only if following 2+ storytellers).
                    // Single-select: a reader views one storyteller at a time.
                    if showAuthorFilter {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Storyteller")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(SL.textSecondary)
                                .tracking(0.5)
                                .textCase(.uppercase)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(uniqueAuthors, id: \.self) { author in
                                        let isSelected = activeAuthor == author
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedAuthor = author
                                                selectedFolderID = nil  // reset category when switching
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "person.crop.circle.fill")
                                                    .font(.system(size: 12))
                                                Text(author)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .lineLimit(1)
                                            }
                                            .foregroundColor(isSelected ? Color(hex: "FDF9F0") : SL.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? SL.primary : SL.surface)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(isSelected ? Color.clear : SL.border, lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Category chips for the active storyteller's folders
                    if !authorFolders.isEmpty {
                        CategoryFilterChips(
                            folders: authorFolders,
                            selection: $selectedFolderID,
                            hasUnfiled: authorStories.contains { $0.folder == nil }
                        )
                    }

                    // Stories grouped by folder
                    if groups.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40))
                                .foregroundColor(SL.textSecondary)
                            Text("No stories yet")
                                .font(SL.heading(18))
                                .foregroundColor(SL.textPrimary)
                            Text("Stories shared with you will appear here")
                                .font(SL.body(14))
                                .foregroundColor(SL.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(40)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Folder section header — suppressed when a flat sort
                                    // ignores grouping, or a single category is selected
                                    if !isFlatSort && selectedFolderID == nil {
                                        HStack(spacing: 6) {
                                            Image(systemName: group.folder != nil ? "folder.fill" : "tray.fill")
                                                .font(.system(size: 11))
                                                .foregroundColor(SL.accent)
                                            Text(group.folder?.name ?? "Unfiled")
                                                .font(.system(size: 12, weight: .semibold))
                                                .tracking(0.5)
                                                .textCase(.uppercase)
                                                .foregroundColor(SL.textSecondary)
                                            Text("· \(group.stories.count)")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(SL.textSecondary.opacity(0.6))
                                        }
                                        .padding(.horizontal, 20)
                                    }

                                    // Stories in this folder
                                    VStack(spacing: 12) {
                                        ForEach(group.stories) { story in
                                            NavigationLink(value: story.uuid) {
                                                StoryCardForReader(story: story)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 4)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SL.background, for: .navigationBar)
            .navigationDestination(for: UUID.self) { storyId in
                if let story = stories.first(where: { $0.uuid == storyId }) {
                    StoryReadingView(story: story)
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
        .sheet(isPresented: $showAddVault) {
            AddStoryVaultView()
        }
        .onAppear {
            // Pin the resolved author so the stored value stays valid even if the
            // reader later joins another vault (activeAuthor falls back to first).
            if selectedAuthor.isEmpty, let first = uniqueAuthors.first {
                selectedAuthor = first
            }
        }
    }
}

struct StoryCardForReader: View {
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
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(SL.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                if let year = story.year {
                    Text(String(year))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SL.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SL.surface.opacity(0.8))
                        .clipShape(Capsule())
                }
            }

            Text(story.content)
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .lineLimit(2)

            HStack(spacing: 6) {
                if let author = story.authorName {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(SL.textSecondary)
                    Text(author)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(SL.textSecondary)
                        .lineLimit(1)
                    Text("·")
                        .foregroundColor(SL.textSecondary)
                }
                Text(story.dateFormatted)
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Text("Read")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(SL.textAccent)
            }
        }
        .padding(16)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
        .contentShape(Rectangle())
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    SampleData.seedStories(in: container.mainContext)
    return ReaderStoriesView()
        .modelContainer(container)
}
