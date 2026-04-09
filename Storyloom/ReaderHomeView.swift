import SwiftUI
import SwiftData

struct ReaderHomeView: View {
    @Binding var selectedTab: Int
    @AppStorage("userName") private var userName = "John"
    @Query(filter: #Predicate<StoryEntry> { $0.isInVault == true },
           sort: \StoryEntry.dateCreated, order: .reverse)
    private var vaultStories: [StoryEntry]
    @State private var showAddVault = false

    private var recentStories: [StoryEntry] { Array(vaultStories.prefix(5)) }
    private var totalCount: Int { vaultStories.count }

    private var newThisWeek: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return vaultStories.filter { $0.dateCreated >= weekAgo }.count
    }

    private var storytellerDisplay: String {
        let names = Array(Set(vaultStories.compactMap { $0.authorName }))
        if names.count == 1 { return "from \(names[0])" }
        return "shared with you"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Greeting header
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Good morning, \(userName)")
                                .font(SL.heading(28))
                                .foregroundColor(SL.textPrimary)
                            Text("Stories shared with you")
                                .font(SL.body(16))
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
                    }

                    if vaultStories.isEmpty {
                        ReaderEmptyState()
                    } else {
                        // Stat cards
                        HStack(spacing: 12) {
                            ReaderStatCard(
                                icon: "books.vertical.fill",
                                value: "\(totalCount)",
                                label: totalCount == 1 ? "story" : "stories"
                            )
                            ReaderStatCard(
                                icon: "sparkles",
                                value: "\(newThisWeek)",
                                label: "new this week"
                            )
                        }

                        // Recent stories (up to 5)
                        VStack(spacing: 12) {
                            ForEach(recentStories) { story in
                                NavigationLink(destination: StoryDetailView(story: story)) {
                                    ReaderStoryCard(story: story)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // View all stories button
                        Button(action: { selectedTab = 1 }) {
                            HStack(spacing: 6) {
                                Text("View all stories")
                                    .font(.system(size: 15, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(SL.accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(SL.background)
        }
        .sheet(isPresented: $showAddVault) {
            AddStoryVaultView()
        }
    }
}

// MARK: - Stat Card

struct ReaderStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ZStack {
                Circle()
                    .fill(SL.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(SL.accent)
            }

            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(SL.textPrimary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SL.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
    }
}

// MARK: - Story Card

struct ReaderStoryCard: View {
    let story: StoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Story image
            StoryImagePlaceholder(story: story)
                .frame(height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Folder badge (if story is in a folder)
            if let folderName = story.folder?.name {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundColor(SL.accent)
                    Text(folderName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SL.accent)
                }
            }

            HStack(alignment: .top) {
                Text(story.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(SL.textPrimary)
                Spacer()
                if let year = story.year {
                    Text(formatCardYear(year))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(SL.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SL.surface.opacity(0.8))
                        .clipShape(Capsule())
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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SL.border, lineWidth: 1)
        )
    }

    private func formatCardYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ""
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }
}

// MARK: - Reading View

struct StoryReadingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audio = AudioManager.shared
    let story: StoryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title + date
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title)
                        .font(SL.heading(26))
                        .foregroundColor(SL.textPrimary)

                    HStack(spacing: 8) {
                        Text(story.dateFormatted)
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                        if let year = story.year {
                            Text("·")
                                .foregroundColor(SL.textSecondary)
                            Text(formatYear(year))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SL.accent)
                        }
                    }
                }

                // Narration player
                if story.publishNarration, let fileName = story.narrationFileName {
                    HStack(spacing: 14) {
                        Button(action: {
                            if audio.isPlaying {
                                audio.stop()
                            } else {
                                audio.play(fileName: fileName)
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(SL.primary)
                                    .frame(width: 44, height: 44)
                                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(SL.accent)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(audio.isPlaying ? "Playing narration…" : "Listen to narration")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(SL.textPrimary)

                            HStack(spacing: 3) {
                                ForEach([0.5, 0.8, 1.0, 0.6, 0.9, 0.4, 0.7, 0.5, 1.0, 0.6], id: \.self) { h in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(audio.isPlaying ? SL.accent : SL.border)
                                        .frame(width: 3, height: 20 * h)
                                }
                            }
                            .frame(height: 20)
                        }

                        Spacer()

                        Image(systemName: audio.isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 16))
                            .foregroundColor(audio.isPlaying ? SL.accent : SL.textSecondary)
                            .padding(8)
                            .background(SL.surface)
                            .clipShape(Circle())
                    }
                    .padding(14)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(audio.isPlaying ? SL.accent.opacity(0.4) : SL.border, lineWidth: audio.isPlaying ? 1.5 : 1))
                }

                Rectangle()
                    .fill(SL.border)
                    .frame(height: 1)

                Text(story.content.isEmpty ? "No story content yet." : story.content)
                    .font(SL.serif(18))
                    .foregroundColor(SL.textPrimary)
                    .lineSpacing(8)

                HStack(spacing: 12) {
                    ReactionButton(icon: "heart.fill", label: "Loved this")
                    ReactionButton(icon: "bubble.left.fill", label: "Leave a comment")
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(SL.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                    }
                    .foregroundColor(SL.accent)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17))
                        .foregroundColor(SL.accent)
                }
            }
        }
    }

    private func formatYear(_ year: Int) -> String {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = ""
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: year)) ?? "\(year)"
    }
}

// MARK: - Reaction Button

struct ReactionButton: View {
    let icon: String
    let label: String

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(SL.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(SL.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
        }
    }
}

// MARK: - Empty State

struct ReaderEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 36))
                .foregroundColor(SL.accent.opacity(0.5))
            Text("No stories yet")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(SL.textPrimary)
            Text("When a storyteller adds stories to their vault and shares access with you, they'll appear here.")
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

// MARK: - Sample Image Helper

struct StoryImagePlaceholder: View {
    let story: StoryEntry

    var sampleImage: some View {
        let hash = abs(story.uuid.hashValue)
        let imageIndex = hash % 6

        switch imageIndex {
        case 0:
            return AnyView(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "D4A574"), Color(hex: "A0826D")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(Text("🐕").font(.system(size: 32)))
            )
        case 1:
            return AnyView(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "C9A961"), Color(hex: "9B7653")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(Text("🐈").font(.system(size: 32)))
            )
        case 2:
            return AnyView(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "CD9B7A"), Color(hex: "9E6F52")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(Text("🦁").font(.system(size: 32)))
            )
        case 3:
            return AnyView(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "D8B5A0"), Color(hex: "A68577")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(Text("🐻").font(.system(size: 32)))
            )
        case 4:
            return AnyView(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "C8A882"), Color(hex: "96755A")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(Text("🦊").font(.system(size: 32)))
            )
        default:
            return AnyView(
                LinearGradient(gradient: Gradient(colors: [Color(hex: "D4A584"), Color(hex: "A27A63")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay(Text("🦌").font(.system(size: 32)))
            )
        }
    }

    var body: some View {
        sampleImage
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var selectedTab = 0
        var body: some View {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
            SampleData.seedStories(in: container.mainContext)
            return ReaderHomeView(selectedTab: $selectedTab)
                .modelContainer(container)
        }
    }
    return PreviewWrapper()
}
