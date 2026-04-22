import SwiftUI
import SwiftData
import Supabase

// MARK: - Real Reader Model

struct RealReader: Identifiable {
    let id: UUID
    let name: String
    let email: String
    let joinedDate: Date
}

// MARK: - ReadersView (real data)

struct ReadersView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var showManageSheet = false
    @State private var showInviteSheet = false
    @State private var readers: [RealReader] = []
    @State private var isLoadingReaders = false

    private var subtitleText: String {
        readers.isEmpty ? "No readers yet" : "\(readers.count) member\(readers.count == 1 ? "" : "s") reading your stories"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Readers")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text(subtitleText)
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

                            ForEach(readers) { reader in
                                VStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(avatarColor(for: reader.id))
                                            .frame(width: 52, height: 52)
                                        Text(String(reader.name.prefix(1)).uppercased())
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(SL.primary)
                                    }
                                    Text(reader.name.components(separatedBy: " ").first ?? reader.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(SL.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }

                    if readers.isEmpty && !isLoadingReaders {
                        VStack(spacing: 12) {
                            Image(systemName: "person.2")
                                .font(.system(size: 32))
                                .foregroundColor(SL.accent.opacity(0.4))
                            Text("No readers yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SL.textPrimary)
                            Text("Invite family and friends to read your stories.")
                                .font(SL.body(14))
                                .foregroundColor(SL.textSecondary)
                                .multilineTextAlignment(.center)
                            Button(action: { showInviteSheet = true }) {
                                Text("Invite someone")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "FDF9F0"))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(SL.primary)
                                    .clipShape(Capsule())
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(SL.background)
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear { fetchReaders() }
        }
        .sheet(isPresented: $showManageSheet) {
            ManageReadersSheet(readers: $readers, isPresented: $showManageSheet)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteReadersSheet(isPresented: $showInviteSheet)
        }
    }

    private func fetchReaders() {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        isLoadingReaders = true
        Task {
            do {
                // Fetch story IDs for this storyteller
                struct StoryIdRow: Decodable {
                    let id: UUID
                }
                let stories: [StoryIdRow] = try await SupabaseManager.shared.client
                    .from("stories")
                    .select("id")
                    .eq("owner_id", value: uid.uuidString)
                    .execute()
                    .value

                let storyIds = stories.map { $0.id.uuidString }
                guard !storyIds.isEmpty else {
                    await MainActor.run { isLoadingReaders = false }
                    return
                }

                // Fetch story_access rows for those stories + profile info
                struct AccessRow: Decodable {
                    let userId: UUID
                    let dateGranted: Date
                    enum CodingKeys: String, CodingKey {
                        case userId = "user_id"
                        case dateGranted = "date_granted"
                    }
                }
                let accessRows: [AccessRow] = try await SupabaseManager.shared.client
                    .from("story_access")
                    .select("user_id, date_granted")
                    .in("story_id", values: storyIds)
                    .execute()
                    .value

                // Collect unique user IDs
                var seenIds = Set<UUID>()
                var uniqueAccess: [AccessRow] = []
                for row in accessRows {
                    if !seenIds.contains(row.userId) {
                        seenIds.insert(row.userId)
                        uniqueAccess.append(row)
                    }
                }

                // Fetch profiles for those user IDs
                struct ProfileRow: Decodable {
                    let id: UUID
                    let name: String?
                    let email: String?
                }
                let profileIds = uniqueAccess.map { $0.userId.uuidString }
                let profiles: [ProfileRow] = profileIds.isEmpty ? [] : try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("id, name, email")
                    .in("id", values: profileIds)
                    .execute()
                    .value

                let profileById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
                let result: [RealReader] = uniqueAccess.compactMap { access in
                    guard let profile = profileById[access.userId] else { return nil }
                    return RealReader(
                        id: access.userId,
                        name: profile.name ?? profile.email ?? "Reader",
                        email: profile.email ?? "",
                        joinedDate: access.dateGranted
                    )
                }

                await MainActor.run {
                    readers = result
                    isLoadingReaders = false
                }
            } catch {
                print("ReadersView: fetch readers failed — \(error.localizedDescription)")
                await MainActor.run { isLoadingReaders = false }
            }
        }
    }

    private func avatarColor(for id: UUID) -> Color {
        let colors: [Color] = [
            Color(hex: "EAE0C8"), Color(hex: "D5E0CC"), Color(hex: "E8D5C4"),
            Color(hex: "D8E8E0"), Color(hex: "E8DCE8"), Color(hex: "E0E8D8")
        ]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Manage Readers Sheet

struct ManageReadersSheet: View {
    @Binding var readers: [RealReader]
    @Binding var isPresented: Bool
    @State private var readerToRemove: RealReader? = nil
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
                    if readers.isEmpty {
                        Text("No readers yet")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(readers) { reader in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(avatarColor(for: reader.id))
                                        .frame(width: 42, height: 42)
                                    Text(String(reader.name.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(SL.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reader.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(SL.textPrimary)
                                    Text("Joined \(reader.joinedDate.formatted(date: .abbreviated, time: .omitted))")
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
                    removeReader(toRemove)
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

    private func removeReader(_ reader: RealReader) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        // Remove from local list immediately
        readers.removeAll { $0.id == reader.id }
        // Delete from Supabase story_access for all stories owned by current user
        Task {
            do {
                // Get all story IDs owned by current user
                struct StoryIdRow: Decodable { let id: UUID }
                let stories: [StoryIdRow] = try await SupabaseManager.shared.client
                    .from("stories")
                    .select("id")
                    .eq("owner_id", value: uid.uuidString)
                    .execute()
                    .value
                let storyIds = stories.map { $0.id.uuidString }
                guard !storyIds.isEmpty else { return }
                // Delete story_access rows
                try await SupabaseManager.shared.client
                    .from("story_access")
                    .delete()
                    .eq("user_id", value: reader.id.uuidString)
                    .in("story_id", values: storyIds)
                    .execute()
            } catch {
                print("ManageReadersSheet: remove reader failed — \(error.localizedDescription)")
            }
        }
    }

    private func avatarColor(for id: UUID) -> Color {
        let colors: [Color] = [
            Color(hex: "EAE0C8"), Color(hex: "D5E0CC"), Color(hex: "E8D5C4"),
            Color(hex: "D8E8E0"), Color(hex: "E8DCE8"), Color(hex: "E0E8D8")
        ]
        let index = abs(id.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Invite Readers Sheet

struct InviteReadersSheet: View {
    @Binding var isPresented: Bool
    @State private var inviteCode: String = ""
    @State private var isGenerating = true
    @State private var showShareSheet = false
    @State private var didCopy = false

    private var inviteLink: String { "storyloom://join/\(inviteCode)" }
    private var shareMessage: String {
        "You've been invited to read stories on Storyloom!\n\nUse invite code: \(inviteCode)\n\nAlready have the app? Tap to join: storyloom://join/\(inviteCode)"
    }

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

                // Invite code display
                if isGenerating {
                    ProgressView()
                        .tint(SL.accent)
                } else {
                    VStack(spacing: 6) {
                        Text("Invite code")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(SL.textSecondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(inviteCode)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(SL.textPrimary)
                            .tracking(4)
                        Text("Valid for 7 days")
                            .font(SL.body(12))
                            .foregroundColor(SL.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    Button(action: {
                        UIPasteboard.general.string = inviteLink
                        didCopy = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { didCopy = false }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: didCopy ? "checkmark.circle.fill" : "link")
                                .font(.system(size: 16))
                            Text(didCopy ? "Copied!" : "Copy invite link")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(didCopy ? SL.accent : SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isGenerating)

                    ShareLink(item: shareMessage) {
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
                    .disabled(isGenerating)
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
            .onAppear { generateInviteCode() }
        }
    }

    private func generateInviteCode() {
        guard let uid = AuthManager.shared.supabaseUserId else {
            isGenerating = false
            return
        }
        // Generate a 6-char alphanumeric code
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let code = String((0..<6).map { _ in chars.randomElement()! })
        let expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60)

        Task {
            do {
                struct InviteInsert: Encodable {
                    let ownerId: UUID
                    let code: String
                    let expiresAt: Date
                    enum CodingKeys: String, CodingKey {
                        case ownerId = "owner_id"
                        case code
                        case expiresAt = "expires_at"
                    }
                }
                let payload = InviteInsert(ownerId: uid, code: code, expiresAt: expiresAt)
                try await SupabaseManager.shared.client
                    .from("story_invites")
                    .insert(payload)
                    .execute()
                await MainActor.run {
                    inviteCode = code
                    isGenerating = false
                }
            } catch {
                print("InviteReadersSheet: generate code failed — \(error.localizedDescription)")
                await MainActor.run {
                    // Still show a code locally even if insert failed
                    inviteCode = code
                    isGenerating = false
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
