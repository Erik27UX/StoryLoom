import SwiftUI
import SwiftData
import Supabase

struct ManageStoryVaultsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var stories: [StoryEntry]

    @State private var storytellerToRemove: String? = nil
    @State private var showConfirmAlert = false

    /// Unique storytellers derived from local story records, with story counts.
    private var storytellers: [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for story in stories {
            if let name = story.authorName {
                counts[name, default: 0] += 1
            }
        }
        return counts
            .map { (name: $0.key, count: $0.value) }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            if storytellers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(SL.textSecondary)
                    Text("No story vaults connected")
                        .font(SL.heading(18))
                        .foregroundColor(SL.textPrimary)
                    Text("Add a story vault on the Stories tab using an invite code or link.")
                        .font(SL.body(14))
                        .foregroundColor(SL.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Removing a storyteller deletes all their stories from your library. You'll need their invite code or link to reconnect.")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(storytellers, id: \.name) { storyteller in
                                HStack(spacing: 12) {
                                    // Avatar initial
                                    ZStack {
                                        Circle()
                                            .fill(SL.accent.opacity(0.12))
                                            .frame(width: 40, height: 40)
                                        Text(String(storyteller.name.prefix(1)).uppercased())
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(SL.textAccent)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(storyteller.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(SL.textPrimary)
                                        Text("\(storyteller.count) \(storyteller.count == 1 ? "story" : "stories")")
                                            .font(SL.body(13))
                                            .foregroundColor(SL.textSecondary)
                                    }

                                    Spacer()

                                    Button(action: {
                                        storytellerToRemove = storyteller.name
                                        showConfirmAlert = true
                                    }) {
                                        Text("Remove")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)

                                if storyteller.name != storytellers.last?.name {
                                    Divider()
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Story Vaults")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                    }
                    .foregroundColor(SL.textAccent)
                }
            }
        }
        .confirmationDialog(
            "Remove storyteller?",
            isPresented: $showConfirmAlert,
            titleVisibility: .visible
        ) {
            if let name = storytellerToRemove {
                Button("Remove \(name)", role: .destructive) {
                    removeStoryteller(name)
                }
                Button("Cancel", role: .cancel) {}
            }
        } message: {
            if let name = storytellerToRemove {
                let count = storytellers.first(where: { $0.name == name })?.count ?? 0
                Text("You'll lose access to all \(count) \(count == 1 ? "story" : "stories") from \(name). You'll need their invite code or link to reconnect.")
            }
        }
    }

    private func removeStoryteller(_ name: String) {
        let toDelete = stories.filter { $0.authorName == name }
        let storyIds = toDelete.map { $0.uuid.uuidString }

        // Remove local records first so the UI updates immediately
        for story in toDelete {
            modelContext.delete(story)
        }

        // Best-effort Supabase cleanup: remove story_access rows for these
        // stories so they don't reappear on the next sync pull.
        guard !storyIds.isEmpty,
              let readerId = AuthManager.shared.supabaseUserId else { return }
        Task {
            _ = try? await SupabaseManager.shared.client
                .from("story_access")
                .delete()
                .in("story_id", values: storyIds)
                .eq("user_id", value: readerId.uuidString)
                .execute()
        }
    }
}

#Preview {
    NavigationStack {
        ManageStoryVaultsView()
    }
}
