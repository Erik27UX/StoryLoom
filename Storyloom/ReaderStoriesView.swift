import SwiftUI
import SwiftData

struct ReaderStoriesView: View {
    @Query private var stories: [StoryEntry]
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]
    @State private var selectedAuthors = Set<String>()
    @State private var hasInitialized = false
    @State private var sortBy: SortOption = .created
    @State private var showAddVault = false
    @State private var searchText = ""

    var uniqueAuthors: [String] {
        let authors = stories.compactMap { $0.authorName ?? "Your Stories" }
        return Array(Set(authors)).sorted()
    }

    var groupedFilteredStories: [(folder: Folder?, stories: [StoryEntry])] {
        let activeAuthors = selectedAuthors.isEmpty ? Set(uniqueAuthors) : selectedAuthors

        let baseFiltered = stories.filter { story in
            let author = story.authorName ?? "Your Stories"
            return story.isInVault && activeAuthors.contains(author)
        }

        // Apply search filter
        let filtered = searchText.isEmpty ? baseFiltered : baseFiltered.filter { story in
            story.title.localizedCaseInsensitiveContains(searchText) ||
            story.content.localizedCaseInsensitiveContains(searchText)
        }

        // Group by folder
        var grouped: [UUID?: [StoryEntry]] = [:]
        for story in filtered {
            let key = story.folder?.id
            if grouped[key] == nil { grouped[key] = [] }
            grouped[key]?.append(story)
        }

        // Sort stories within each group
        for key in grouped.keys {
            grouped[key]?.sort { lhs, rhs in
                switch sortBy {
                case .created:
                    return lhs.dateCreated > rhs.dateCreated
                case .year:
                    return (lhs.year ?? Int.min) > (rhs.year ?? Int.min)
                case .draft, .published:
                    return lhs.dateCreated > rhs.dateCreated
                }
            }
        }

        var result: [(folder: Folder?, stories: [StoryEntry])] = []

        // Named folders first (in folder creation order)
        for folder in folders {
            if let folderStories = grouped[folder.id], !folderStories.isEmpty {
                result.append((folder, folderStories))
            }
        }

        // Unfiled stories at the bottom
        if let unfiledStories = grouped[nil], !unfiledStories.isEmpty {
            result.append((nil, unfiledStories))
        }

        return result
    }

    var hasAnyStories: Bool {
        !groupedFilteredStories.isEmpty
    }

    var showAuthorFilter: Bool {
        uniqueAuthors.count >= 2
    }

    var body: some View {
        NavigationStack {
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

                    // Author filter pills (only if 2+ storytellers)
                    if showAuthorFilter {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Filter by storyteller")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(SL.textSecondary)
                                .tracking(0.5)
                                .textCase(.uppercase)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    // "All" pill — active when selectedAuthors is empty
                                    Button(action: { selectedAuthors.removeAll() }) {
                                        HStack(spacing: 6) {
                                            Text("All")
                                                .font(.system(size: 13, weight: .medium))
                                            if selectedAuthors.isEmpty {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 12))
                                            }
                                        }
                                        .foregroundColor(selectedAuthors.isEmpty ? .white : SL.textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedAuthors.isEmpty ? SL.accent : SL.surface)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(
                                                selectedAuthors.isEmpty ? SL.accent : SL.border,
                                                lineWidth: 1
                                            )
                                        )
                                    }

                                    ForEach(uniqueAuthors, id: \.self) { author in
                                        Button(action: { toggleAuthor(author) }) {
                                            HStack(spacing: 6) {
                                                Text(author)
                                                    .font(.system(size: 13, weight: .medium))
                                                if selectedAuthors.contains(author) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 12))
                                                }
                                            }
                                            .foregroundColor(selectedAuthors.contains(author) ? .white : SL.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(selectedAuthors.contains(author) ? SL.accent : SL.surface)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(
                                                    selectedAuthors.contains(author) ? SL.accent : SL.border,
                                                    lineWidth: 1
                                                )
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Stories grouped by folder
                    if !hasAnyStories {
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
                            ForEach(Array(groupedFilteredStories.enumerated()), id: \.offset) { _, group in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Folder section header
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

                                    // Stories in this folder
                                    VStack(spacing: 12) {
                                        ForEach(group.stories) { story in
                                            NavigationLink(destination: StoryReadingView(story: story)) {
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
            }
            .refreshable {
                await SyncManager.shared.pullAllUserDataAsync()
            }
            .background(SL.background)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search stories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SL.background, for: .navigationBar)
        }
        .sheet(isPresented: $showAddVault) {
            AddStoryVaultView()
        }
        .onAppear {
            // selectedAuthors starts empty = "All" is active, which is correct
            hasInitialized = true
        }
    }

    private func toggleAuthor(_ author: String) {
        if selectedAuthors.contains(author) {
            selectedAuthors.remove(author)
        } else {
            selectedAuthors.insert(author)
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

            HStack {
                Text(story.dateFormatted)
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Text("Read")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(SL.accent)
            }
        }
        .padding(16)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    SampleData.seedStories(in: container.mainContext)
    return ReaderStoriesView()
        .modelContainer(container)
}
