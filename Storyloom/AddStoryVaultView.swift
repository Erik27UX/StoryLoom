import SwiftUI
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "erikfischer.Storyloom", category: "Vault")

struct AddStoryVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var joinedOwnerName: String? = nil
    @State private var showWelcome = false
    // Rate-limit lives in AppCoordinator (singleton) so it persists across sheet dismiss/re-open.

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
        .sheet(isPresented: $showWelcome, onDismiss: { dismiss() }) {
            if let ownerName = joinedOwnerName {
                VaultWelcomeView(ownerName: ownerName)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .storyloomJoinCode)) { notification in
            if let code = notification.userInfo?["code"] as? String {
                enteredCode = String(code.uppercased().prefix(6))
                if enteredCode.count == 6 {
                    submitCode()
                }
            }
        }
    }

    private func submitCode() {
        let now = Date()
        guard enteredCode.count == 6,
              AuthManager.shared.supabaseUserId != nil,
              now.timeIntervalSince(AppCoordinator.shared.lastVaultJoinTime) > 3 else { return }
        AppCoordinator.shared.lastVaultJoinTime = now

        isLoading = true
        errorMessage = nil
        successMessage = nil

        Task {
            do {
                // Server-side redemption via RPC — validates expiry, prevents self-invite,
                // grants access to all published stories, and increments uses_count atomically.
                struct RedeemResult: Decodable {
                    let ownerName: String
                    enum CodingKeys: String, CodingKey { case ownerName = "owner_name" }
                }
                struct RedeemParams: Encodable {
                    let pCode: String
                    enum CodingKeys: String, CodingKey { case pCode = "p_code" }
                }
                let result: RedeemResult = try await SupabaseManager.shared.client
                    .rpc("redeem_invite", params: RedeemParams(pCode: enteredCode))
                    .execute()
                    .value

                SyncManager.shared.pullAllUserData()

                await MainActor.run {
                    isLoading = false
                    joinedOwnerName = result.ownerName
                    UserDefaults.standard.set(true, forKey: "reader.hasJoinedVault")
                    showWelcome = true
                }
            } catch {
                // Map Supabase error messages to user-friendly strings
                let msg = error.localizedDescription
                await MainActor.run {
                    if msg.contains("invalid_code") || msg.contains("invalid or expired") {
                        errorMessage = "Invalid or expired code. Please check with your storyteller."
                    } else if msg.contains("self_invite") {
                        errorMessage = "You can't use your own invite code."
                    } else {
                        errorMessage = "Something went wrong. Please try again."
                    }
                    isLoading = false
                    logger.error("redeem_invite failed: \(msg, privacy: .private)")
                }
            }
        }
    }
}

// MARK: - Vault Welcome View
// Shown once, immediately after a reader successfully redeems an invite code.
// Orients them to what Storyloom is and what they can do.

struct VaultWelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    let ownerName: String

    private let features: [(icon: String, title: String, body: String)] = [
        ("book.fill",          "Read their stories",     "Browse stories your storyteller has shared — at any time, from anywhere."),
        ("bubble.left.fill",   "Leave comments",          "React to stories and leave notes that your storyteller can read."),
        ("questionmark.bubble.fill", "Ask questions",    "Curious about something? Ask directly and they'll answer in a new story."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Top accent bar
            Rectangle()
                .fill(SL.accent)
                .frame(height: 4)

            ScrollView {
                VStack(spacing: 32) {
                    // Hero
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SL.accent.opacity(0.12))
                                .frame(width: 72, height: 72)
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 30))
                                .foregroundColor(SL.accent)
                        }
                        .padding(.top, 36)

                        Text("You're in!")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)

                        Text("You now have access to \(ownerName)'s story vault. Here's what you can do:")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                    }

                    // Feature rows
                    VStack(spacing: 16) {
                        ForEach(features, id: \.title) { feature in
                            HStack(alignment: .top, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(SL.surface)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 17))
                                        .foregroundColor(SL.accent)
                                }
                                .frame(width: 44)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text(feature.body)
                                        .font(SL.body(13))
                                        .foregroundColor(SL.textSecondary)
                                        .lineSpacing(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(SL.border, lineWidth: 1))

                    // CTA
                    Button(action: { dismiss() }) {
                        Text("Start exploring")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
        }
        .background(SL.background.ignoresSafeArea())
    }
}

#Preview {
    AddStoryVaultView()
}
