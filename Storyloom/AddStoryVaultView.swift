import SwiftUI
import Supabase

struct AddStoryVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {

                // Icon + heading
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(SL.accent.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 24))
                            .foregroundColor(SL.accent)
                    }

                    Text("Add Story Vault")
                        .font(SL.heading(26))
                        .foregroundColor(SL.textPrimary)

                    Text("Enter the 6-character invite code from your storyteller to gain access to their stories.")
                        .font(SL.body(15))
                        .foregroundColor(SL.textSecondary)
                        .lineSpacing(4)
                }

                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invite Code")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SL.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    TextField("E.g. ABC123", text: $enteredCode)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .tracking(4)
                        .padding(14)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(enteredCode.isEmpty ? SL.border : SL.accent, lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: enteredCode) { _, newValue in
                            enteredCode = String(newValue.uppercased().prefix(6))
                            errorMessage = nil
                        }
                }

                // Status messages
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(SL.body(14))
                            .foregroundColor(.red)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if let success = successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(SL.accent)
                        Text(success)
                            .font(SL.body(14))
                            .foregroundColor(SL.textPrimary)
                    }
                    .padding(12)
                    .background(SL.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: { submitCode() }) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text(isLoading ? "Adding..." : "Add Vault")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "FDF9F0"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background((enteredCode.count < 6 || isLoading) ? SL.primary.opacity(0.4) : SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(enteredCode.count < 6 || isLoading)

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }
                }
            }
            .padding(24)
            .background(SL.background)
            .navigationBarHidden(true)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("storyloom.joinCode"))) { notification in
            if let code = notification.userInfo?["code"] as? String {
                enteredCode = String(code.uppercased().prefix(6))
                if enteredCode.count == 6 {
                    submitCode()
                }
            }
        }
    }

    private func submitCode() {
        guard enteredCode.count == 6,
              let currentUserId = AuthManager.shared.supabaseUserId else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                // Look up the invite code
                struct InviteRow: Decodable {
                    let ownerId: UUID
                    let expiresAt: Date
                    enum CodingKeys: String, CodingKey {
                        case ownerId = "owner_id"
                        case expiresAt = "expires_at"
                    }
                }
                let invites: [InviteRow] = try await SupabaseManager.shared.client
                    .from("story_invites")
                    .select("owner_id, expires_at")
                    .eq("code", value: enteredCode)
                    .execute()
                    .value

                guard let invite = invites.first else {
                    await MainActor.run {
                        errorMessage = "Invalid or expired code. Please check with your storyteller."
                        isLoading = false
                    }
                    return
                }

                // Check expiry
                guard invite.expiresAt > Date() else {
                    await MainActor.run {
                        errorMessage = "This invite code has expired. Ask your storyteller for a new one."
                        isLoading = false
                    }
                    return
                }

                let ownerId = invite.ownerId

                // Fetch owner profile name
                struct ProfileRow: Decodable {
                    let name: String?
                }
                let profiles: [ProfileRow] = try await SupabaseManager.shared.client
                    .from("profiles")
                    .select("name")
                    .eq("id", value: ownerId.uuidString)
                    .execute()
                    .value
                let ownerName = profiles.first?.name ?? "your storyteller"

                // Fetch all published stories by that owner
                struct StoryIdRow: Decodable { let id: UUID }
                let stories: [StoryIdRow] = try await SupabaseManager.shared.client
                    .from("stories")
                    .select("id")
                    .eq("owner_id", value: ownerId.uuidString)
                    .eq("is_published", value: true)
                    .execute()
                    .value

                // Insert story_access for each story (ignore duplicates via upsert)
                struct AccessInsert: Encodable {
                    let storyId: UUID
                    let userId: UUID
                    let accessLevel: String
                    let dateGranted: Date
                    enum CodingKeys: String, CodingKey {
                        case storyId = "story_id"
                        case userId = "user_id"
                        case accessLevel = "access_level"
                        case dateGranted = "date_granted"
                    }
                }
                let accessRows = stories.map { story in
                    AccessInsert(storyId: story.id, userId: currentUserId, accessLevel: "view", dateGranted: Date())
                }
                if !accessRows.isEmpty {
                    try await SupabaseManager.shared.client
                        .from("story_access")
                        .upsert(accessRows, onConflict: "story_id,user_id")
                        .execute()
                }

                // Pull updated data
                SyncManager.shared.pullAllUserData()

                await MainActor.run {
                    successMessage = "You've been added to \(ownerName)'s vault."
                    isLoading = false
                    // Auto-dismiss after a moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Something went wrong. Please try again."
                    isLoading = false
                    print("AddStoryVaultView: error — \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    AddStoryVaultView()
}
