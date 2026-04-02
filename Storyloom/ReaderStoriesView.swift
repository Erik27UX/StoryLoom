import SwiftUI
import SwiftData

struct ReaderStoriesView: View {
    @Query(filter: #Predicate<StoryEntry> { $0.isInVault == true },
           sort: \StoryEntry.dateCreated, order: .reverse)
    private var vaultStories: [StoryEntry]
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]
    @State private var sortBy: SortOption = .created

    private var groupedStories: [(folder: Folder?, stories: [StoryEntry])] {
        // Create a dictionary grouped by folder
        var grouped: [UUID?: [StoryEntry]] = [:]

        for story in vaultStories {
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
                case .year:
                    return (lhs.year ?? 0) > (rhs.year ?? 0)
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Story vault")
                                .font(SL.heading(28))
                                .foregroundColor(SL.textPrimary)
                            Text("Stories shared with you")
                                .font(SL.body(16))
                                .foregroundColor(SL.textSecondary)
                        }

                        Spacer()

                        // Sort toggle
                        Menu {
                            Button(action: { sortBy = .created }) {
                                HStack {
                                    Text("📅 Created")
                                    if sortBy == .created {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            Button(action: { sortBy = .year }) {
                                HStack {
                                    Text("📆 Year")
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

                    if vaultStories.isEmpty {
                        ReaderEmptyState()
                    } else {
                        // Display grouped stories
                        ForEach(groupedStories, id: \.folder?.id) { folder, stories in
                            VStack(alignment: .leading, spacing: 12) {
                                // Folder header
                                Text(folder?.name ?? "Unfiled")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(1)
                                    .textCase(.uppercase)
                                    .foregroundColor(SL.textSecondary)

                                // Stories in folder
                                ForEach(stories) { story in
                                    NavigationLink(destination: StoryReadingView(story: story)) {
                                        ReaderStoryCard(story: story)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(SL.background)
        }
    }
}

#Preview {
    ReaderStoriesView()
}
