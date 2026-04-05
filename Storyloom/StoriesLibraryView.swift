import SwiftUI
import SwiftData

struct StoriesLibraryView: View {
    @Query(sort: \StoryEntry.dateCreated, order: .reverse) private var allStories: [StoryEntry]
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]
    @State private var sortBy: SortOption = .created

    private var groupedStories: [(folder: Folder?, stories: [StoryEntry])] {
        // Create a dictionary grouped by folder
        var grouped: [UUID?: [StoryEntry]] = [:]

        for story in allStories {
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
                        Text("Your stories")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)

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
                                // Folder header
                                Text(folder?.name ?? "Unfiled")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(1)
                                    .textCase(.uppercase)
                                    .foregroundColor(SL.textSecondary)

                                // Stories in folder
                                ForEach(stories) { story in
                                    NavigationLink(destination: StoryDetailView(story: story)) {
                                        StoryLibraryCard(story: story)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Locked upgrade card
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

                        Button(action: {}) {
                            Text("Unlock \u{2014} $12/month")
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(SL.background)
        }
    }
}

struct StoryLibraryCard: View {
    let story: StoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(SL.accent.opacity(0.15))
                    .frame(height: 80)
                Image(systemName: "photo.fill")
                    .font(.system(size: 24))
                    .foregroundColor(SL.accent.opacity(0.4))
            }

            HStack(alignment: .top) {
                Text(story.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SL.textPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if story.isInVault {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(SL.accent)
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
    }

    private func formatYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ""
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }
}

struct LibraryEmptyState: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.stack")
                .font(.system(size: 32))
                .foregroundColor(SL.accent.opacity(0.5))
            Text("No stories yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(SL.textPrimary)
            Text("Head to the Home tab to answer your first prompt.")
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
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
