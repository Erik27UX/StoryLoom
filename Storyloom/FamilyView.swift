import SwiftUI

// Mock reader model for display
struct MockReader: Identifiable {
    let id = UUID()
    let initial: String
    let name: String
    let bgColor: Color
    let joinedDate: String
}

struct ReadersView: View {
    @State private var showManageSheet = false
    @State private var showInviteSheet = false

    let mockReaders: [MockReader] = [
        MockReader(initial: "S", name: "Sarah",  bgColor: Color(hex: "EAE0C8"), joinedDate: "Joined 2 weeks ago"),
        MockReader(initial: "M", name: "Marcus", bgColor: Color(hex: "D5E0CC"), joinedDate: "Joined 1 month ago"),
        MockReader(initial: "T", name: "Tom",    bgColor: Color(hex: "E8D5C4"), joinedDate: "Joined 3 months ago"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(mockReaders.count) members reading your stories")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
                    }
                    .padding(.top, 4)

                    // Reader avatars + Invite button
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            // Invite button — sits at start of avatar row
                            Button(action: { showInviteSheet = true }) {
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                            .foregroundColor(SL.accent.opacity(0.5))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 18))
                                            .foregroundColor(SL.accent)
                                    }
                                    Text("Invite")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(SL.accent)
                                }
                            }

                            ForEach(mockReaders) { reader in
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(reader.bgColor)
                                            .frame(width: 52, height: 52)
                                        Text(reader.initial)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(SL.primary)
                                    }
                                    Text(reader.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(SL.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }

                    // Activity cards
                    VStack(spacing: 12) {
                        // Sarah loved
                        ReaderActivityFeedCard(
                            icon: "heart.fill",
                            iconColor: Color(hex: "C17B6A"),
                            title: "Sarah loved your story",
                            subtitle: "The summer I turned sixteen",
                            reactionTags: ["Loved this", "Want more"],
                            actionLabel: nil,
                            action: nil
                        )

                        // Mark asked a question
                        ReaderActivityFeedCard(
                            icon: "bubble.left.fill",
                            iconColor: SL.accent,
                            title: "Marcus asked a question",
                            subtitle: "Dad, what happened next with the car?",
                            reactionTags: [],
                            actionLabel: "Answer Marcus's question",
                            action: {}
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(SL.background)
            .navigationTitle("Readers")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(SL.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showManageSheet = true }) {
                        Text("Manage Readers")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(SL.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showManageSheet) {
            ManageReadersSheet(readers: mockReaders, isPresented: $showManageSheet)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteReadersSheet(isPresented: $showInviteSheet)
        }
    }
}

// MARK: - Manage Readers Sheet

struct ManageReadersSheet: View {
    @State var readers: [MockReader]
    @Binding var isPresented: Bool
    @State private var readerToRemove: MockReader? = nil
    @State private var showRemoveConfirm = false
    @State private var showInviteFromManage = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: { showInviteFromManage = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(SL.accent.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 15))
                                    .foregroundColor(SL.accent)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Invite a new reader")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SL.accent)
                                Text("Share a private link to grant access")
                                    .font(SL.body(12))
                                    .foregroundColor(SL.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(SL.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Invite")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SL.textSecondary)
                        .textCase(.uppercase)
                }

                Section {
                    ForEach(readers) { reader in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(reader.bgColor)
                                    .frame(width: 42, height: 42)
                                Text(reader.initial)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(SL.primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reader.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SL.textPrimary)
                                Text(reader.joinedDate)
                                    .font(SL.body(12))
                                    .foregroundColor(SL.textSecondary)
                            }
                            Spacer()
                            Button(action: {
                                readerToRemove = reader
                                showRemoveConfirm = true
                            }) {
                                Text("Remove")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.red.opacity(0.8))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Current readers")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SL.textSecondary)
                        .textCase(.uppercase)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(SL.background)
            .navigationTitle("Manage Readers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(SL.accent)
                }
            }
        }
        .background(SL.background)
        .confirmationDialog(
            "Remove \(readerToRemove?.name ?? "reader")?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove access", role: .destructive) {
                if let toRemove = readerToRemove {
                    readers.removeAll { $0.id == toRemove.id }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They will no longer be able to read your stories.")
        }
        .sheet(isPresented: $showInviteFromManage) {
            InviteReadersSheet(isPresented: $showInviteFromManage)
        }
    }
}

// MARK: - Invite Readers Sheet

struct InviteReadersSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(SL.accent.opacity(0.1))
                            .frame(width: 72, height: 72)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 30))
                            .foregroundColor(SL.accent)
                    }
                    Text("Invite a reader")
                        .font(SL.heading(22))
                        .foregroundColor(SL.textPrimary)
                    Text("Share a private link with someone you'd like to read your stories.")
                        .font(SL.body(14))
                        .foregroundColor(SL.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    Button(action: {}) {
                        HStack(spacing: 10) {
                            Image(systemName: "link")
                                .font(.system(size: 16))
                            Text("Copy invite link")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: {}) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                            Text("Share via...")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(SL.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(SL.accent)
                }
            }
        }
    }
}

// MARK: - Shared Components

struct ReaderActivityFeedCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let reactionTags: [String]
    let actionLabel: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(SL.textPrimary)
            }

            Text(subtitle)
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .italic()

            if !reactionTags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(reactionTags, id: \.self) { tag in
                        Text(tag)
                            .font(SL.body(12))
                            .foregroundColor(SL.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(SL.background)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(SL.border, lineWidth: 1))
                    }
                }
            }

            if let label = actionLabel, let action {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(SL.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
    }
}

struct AvatarCircle: View {
    let initial: String
    let bgColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: 48, height: 48)
            Text(initial)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SL.primary)
        }
    }
}

struct ReactionPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SL.body(12))
            .foregroundColor(SL.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(SL.background)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(SL.border, lineWidth: 1))
    }
}

#Preview {
    ReadersView()
}
