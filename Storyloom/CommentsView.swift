import SwiftUI
import SwiftData

struct CommentsView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var authManager = AuthManager.shared
    @Query private var comments: [StoryComment]

    let story: StoryEntry
    @State private var newComment = ""
    @State private var replyingTo: StoryComment? = nil
    @State private var replyText = ""

    private let maxCommentLength = 2000

    /// Single-pass over the story's comments — avoids an O(n²) scan when rendering replies.
    /// Returns sorted top-level comments and a [parentId → replies] dictionary.
    private var processedComments: (topLevel: [StoryComment], byParent: [UUID: [StoryComment]]) {
        let storyComments = comments.filter { $0.storyId == story.uuid }
        var topLevel: [StoryComment] = []
        var byParent: [UUID: [StoryComment]] = [:]
        for c in storyComments {
            if let parentId = c.parentCommentId {
                byParent[parentId, default: []].append(c)
            } else {
                topLevel.append(c)
            }
        }
        topLevel.sort { $0.dateCreated < $1.dateCreated }
        for key in byParent.keys { byParent[key]!.sort { $0.dateCreated < $1.dateCreated } }
        return (topLevel, byParent)
    }

    var isStoryteller: Bool { authManager.currentUser?.role == .storyteller }

    var body: some View {
        let (topComments, byParent) = processedComments
        ZStack(alignment: .bottom) {
            SL.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    if topComments.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 40))
                                .foregroundColor(SL.textSecondary)
                            Text("No comments yet")
                                .font(SL.heading(18))
                                .foregroundColor(SL.textPrimary)
                            Text("Be the first to leave a comment")
                                .font(SL.body(14))
                                .foregroundColor(SL.textSecondary)
                        }
                        .padding(40)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(topComments) { comment in
                                VStack(spacing: 0) {
                                    CommentRow(comment: comment, isStoryteller: isStoryteller, isReply: false, onReply: {
                                        withAnimation { replyingTo = (replyingTo?.id == comment.id) ? nil : comment }
                                    })

                                    ForEach(byParent[comment.id] ?? []) { reply in
                                        HStack(alignment: .top, spacing: 0) {
                                            Rectangle()
                                                .fill(SL.accent.opacity(0.25))
                                                .frame(width: 2)
                                                .padding(.leading, 32)
                                                .padding(.vertical, 4)
                                            CommentRow(comment: reply, isStoryteller: false, isReply: true, onReply: nil)
                                        }
                                    }

                                    if replyingTo?.id == comment.id {
                                        HStack(spacing: 10) {
                                            TextField("Reply to \(comment.userName)...", text: $replyText)
                                                .font(SL.body(14))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(SL.surface)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .onChange(of: replyText) { _, value in
                                                    if value.count > maxCommentLength {
                                                        replyText = String(value.prefix(maxCommentLength))
                                                    }
                                                }
                                            Button(action: postReply) {
                                                Image(systemName: "paperplane.fill")
                                                    .foregroundColor(replyText.isEmpty ? SL.textSecondary : SL.accent)
                                            }
                                            .disabled(replyText.isEmpty)
                                            Button(action: { replyingTo = nil; replyText = "" }) {
                                                Image(systemName: "xmark.circle")
                                                    .foregroundColor(SL.textSecondary)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(SL.surface.opacity(0.8))
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }

                                    Divider().background(SL.border).padding(.leading, 16)
                                }
                            }
                        }
                        .padding(.bottom, isStoryteller ? 16 : 72)
                    }
                }

                if !isStoryteller {
                    Divider().background(SL.border)
                    VStack(spacing: 4) {
                        HStack(spacing: 12) {
                            TextField("Add a comment...", text: $newComment)
                                .font(SL.body(14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .onChange(of: newComment) { _, value in
                                    if value.count > maxCommentLength {
                                        newComment = String(value.prefix(maxCommentLength))
                                    }
                                }
                            Button(action: postComment) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(newComment.isEmpty ? SL.textSecondary : SL.accent)
                            }
                            .disabled(newComment.isEmpty)
                        }
                        // Character counter — only visible in the last 20% of the limit
                        if newComment.count > maxCommentLength * 4 / 5 {
                            HStack {
                                Spacer()
                                Text("\(newComment.count)/\(maxCommentLength)")
                                    .font(.system(size: 11))
                                    .foregroundColor(newComment.count >= maxCommentLength ? .red : SL.textSecondary)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func postComment() {
        guard !newComment.isEmpty else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let comment = StoryComment(storyId: story.uuid, userName: authManager.currentUser?.name ?? "Reader", text: newComment)
        modelContext.insert(comment)
        SyncManager.shared.pushComment(comment)
        newComment = ""
    }

    private func postReply() {
        guard !replyText.isEmpty, let parent = replyingTo else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let reply = StoryComment(storyId: story.uuid, userName: authManager.currentUser?.name ?? "Storyteller", text: replyText, parentCommentId: parent.id)
        modelContext.insert(reply)
        SyncManager.shared.pushComment(reply)
        replyText = ""
        replyingTo = nil
    }
}

struct CommentRow: View {
    let comment: StoryComment
    let isStoryteller: Bool
    let isReply: Bool
    var onReply: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isReply ? SL.accent.opacity(0.12) : SL.surface)
                    .frame(width: isReply ? 26 : 34, height: isReply ? 26 : 34)
                Text(String(comment.userName.prefix(1)).uppercased())
                    .font(.system(size: isReply ? 11 : 14, weight: .semibold))
                    .foregroundColor(SL.accent)
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(comment.userName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SL.textPrimary)
                    Text(formatDate(comment.dateCreated))
                        .font(SL.body(11))
                        .foregroundColor(SL.textSecondary)
                }
                Text(comment.text)
                    .font(SL.body(13))
                    .foregroundColor(SL.textPrimary)
                    .lineSpacing(4)
                if isStoryteller && !isReply, let onReply {
                    Button(action: onReply) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrowshape.turn.up.left")
                                .font(.system(size: 11))
                            Text("Reply")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(SL.textSecondary)
                    }
                    .padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = Calendar.current.isDateInToday(comment.dateCreated) ? .none : .short
        f.timeStyle = Calendar.current.isDateInToday(comment.dateCreated) ? .short : .none
        return f.string(from: date)
    }
}

#Preview {
    NavigationStack {
        CommentsView(story: StoryEntry(title: "Test", content: "Test content"))
    }
}
