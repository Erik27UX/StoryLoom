import SwiftUI
import SwiftData

struct ReaderStoriesView: View {
    @Query(filter: #Predicate<StoryEntry> { $0.isInVault == true },
           sort: \StoryEntry.dateCreated, order: .reverse)
    private var vaultStories: [StoryEntry]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Story vault")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Stories shared with you")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    if vaultStories.isEmpty {
                        ReaderEmptyState()
                    } else {
                        ForEach(vaultStories) { story in
                            NavigationLink(destination: StoryReadingView(story: story)) {
                                ReaderStoryCard(story: story)
                            }
                            .buttonStyle(.plain)
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
