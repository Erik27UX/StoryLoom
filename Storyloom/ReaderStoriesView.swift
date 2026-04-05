import SwiftUI
import SwiftData

struct ReaderStoriesView: View {
    @Query private var stories: [StoryEntry]
    @State private var selectedAuthors = Set<String>()
    @State private var hasInitialized = false

    var uniqueAuthors: [String] {
        let authors = stories.compactMap { $0.authorName ?? "Your Stories" }
        return Array(Set(authors)).sorted()
    }

    var filteredStories: [StoryEntry] {
        let activeAuthors = selectedAuthors.isEmpty ? Set(uniqueAuthors) : selectedAuthors
        return stories.filter { story in
            let author = story.authorName ?? "Your Stories"
            return story.isInVault && activeAuthors.contains(author)
        }
        .sorted { $0.dateCreated > $1.dateCreated }
    }

    var showAuthorFilter: Bool {
        uniqueAuthors.count >= 2
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stories")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Shared with you")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
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
                                    ForEach(uniqueAuthors, id: \.self) { author in
                                        Button(action: { toggleAuthor(author) }) {
                                            HStack(spacing: 6) {
                                                Text(author)
                                                    .font(.system(size: 13, weight: .medium))
                                                if selectedAuthors.contains(author) || selectedAuthors.isEmpty {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 12))
                                                }
                                            }
                                            .foregroundColor(
                                                (selectedAuthors.contains(author) || selectedAuthors.isEmpty) ? .white : SL.textSecondary
                                            )
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                (selectedAuthors.contains(author) || selectedAuthors.isEmpty) ? SL.accent : SL.surface
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule().stroke(
                                                    (selectedAuthors.contains(author) || selectedAuthors.isEmpty) ? SL.accent : SL.border,
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

                    // Stories list
                    if filteredStories.isEmpty {
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
                        LazyVStack(spacing: 12) {
                            ForEach(filteredStories) { story in
                                NavigationLink(destination: StoryDetailView(story: story)) {
                                    StoryCardForReader(story: story)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                .padding(.top, 4)
            }
            .background(SL.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if !hasInitialized {
                selectedAuthors = Set(uniqueAuthors)
                hasInitialized = true
            }
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(story.title)
                        .font(SL.heading(16))
                        .foregroundColor(SL.textPrimary)
                        .lineLimit(2)

                    Text(story.content)
                        .font(SL.body(13))
                        .foregroundColor(SL.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let year = story.year {
                        Text(String(year))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(SL.accent)
                    }
                }
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(story.dateFormatted)
                        .font(SL.body(12))
                        .foregroundColor(SL.textSecondary)
                }

                Spacer()

                HStack(spacing: 6) {
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
                        .padding(.vertical, 3)
                        .background(SL.accent.opacity(0.1))
                        .clipShape(Capsule())
                    } else {
                        Text("Private")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SL.surface)
                            .clipShape(Capsule())
                    }
                }
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
