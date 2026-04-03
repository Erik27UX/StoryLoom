import SwiftUI
import SwiftData

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager = AuthManager.shared
    @Query private var comments: [StoryComment]

    let story: StoryEntry
    @State private var newComment = ""
    @State private var showCommentInput = false

    var filteredComments: [StoryComment] {
        let realComments = comments.filter { $0.storyId == story.uuid }
        let mockComments = [
            StoryComment(storyId: story.uuid, userName: "Sarah M.", text: "What a beautiful memory! This reminds me of my own childhood summers."),
            StoryComment(storyId: story.uuid, userName: "James L.", text: "So touching. Thank you for sharing this with us."),
        ]
        return (realComments + mockComments).sorted { $0.dateCreated > $1.dateCreated }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SL.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        if filteredComments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 40))
                                    .foregroundColor(SL.textSecondary)
                                Text("No comments yet")
                                    .font(SL.heading(18))
                                    .foregroundColor(SL.textPrimary)
                                Text("Be the first to comment on this story")
                                    .font(SL.body(14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .padding(40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(filteredComments) { comment in
                                    CommentRow(comment: comment)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }

                    Divider().background(SL.border)

                    // Comment input
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $newComment)
                            .font(SL.body(14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        if !newComment.isEmpty {
                            Button(action: { postComment() }) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(SL.accent)
                                    .padding(8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func postComment() {
        _ = StoryComment(
            storyId: story.uuid,
            userName: authManager.currentUser?.name ?? "User",
            text: newComment
        )
        newComment = ""
    }
}

struct CommentRow: View {
    let comment: StoryComment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SL.surface)
                        .frame(width: 32, height: 32)
                    Text(String(comment.userName.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(SL.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.userName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SL.textPrimary)
                    Text(formatDate(comment.dateCreated))
                        .font(SL.body(11))
                        .foregroundColor(SL.textSecondary)
                }

                Spacer()
            }

            Text(comment.text)
                .font(SL.body(13))
                .foregroundColor(SL.textPrimary)
                .lineSpacing(4)
        }
        .padding(12)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

#Preview {
    CommentsView(story: StoryEntry(title: "Test", content: "Test content"))
}
