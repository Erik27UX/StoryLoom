import SwiftUI

// MARK: - DeleteAccountView
// Full-screen confirmation for permanent account deletion.
//
// Account deletion is irreversible and wipes content the user may never be able
// to recreate — voice recordings of family members in particular. A single
// tap-through dialog isn't proportionate to that, so this screen spells out
// exactly what disappears and requires the word DELETE to be typed before the
// destructive button becomes active.

struct DeleteAccountView: View {
    @Binding var isPresented: Bool
    @ObservedObject var authManager: AuthManager

    @State private var confirmationText = ""
    @State private var isDeleting = false

    private let requiredPhrase = "DELETE"

    private var canDelete: Bool {
        confirmationText.trimmingCharacters(in: .whitespaces).uppercased() == requiredPhrase && !isDeleting
    }

    private let consequences: [(icon: String, title: String, detail: String)] = [
        ("books.vertical.fill", "Every story you've written",
         "All drafts and published stories, permanently erased."),
        ("waveform", "All voice recordings",
         "Your narrations can't be recovered once deleted."),
        ("photo.fill", "All photos you've added",
         "Images attached to your stories are removed."),
        ("person.2.fill", "Your readers' access",
         "Family members lose access to everything you've shared."),
        ("bubble.left.and.bubble.right.fill", "Comments and questions",
         "All conversations on your stories are deleted.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Warning header
                    VStack(alignment: .leading, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E63946").opacity(0.12))
                                .frame(width: 60, height: 60)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(Color(hex: "C1121F"))
                        }

                        Text("Delete your account?")
                            .font(SL.heading(26))
                            .foregroundColor(SL.textPrimary)

                        Text("This cannot be undone. There is no way to recover your account or anything in it.")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // What gets deleted
                    VStack(alignment: .leading, spacing: 14) {
                        Text("What you'll lose")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundColor(SL.textSecondary)

                        ForEach(consequences, id: \.title) { item in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "C1121F"))
                                    .frame(width: 22, alignment: .center)
                                    .padding(.top, 2)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(SL.textPrimary)
                                    Text(item.detail)
                                        .font(SL.body(13))
                                        .foregroundColor(SL.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))

                    // Typed confirmation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type DELETE to confirm")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SL.textPrimary)

                        TextField("DELETE", text: $confirmationText)
                            .font(SL.body(16))
                            .foregroundColor(SL.textPrimary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .padding(14)
                            .background(SL.background)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(canDelete ? Color(hex: "C1121F") : SL.border, lineWidth: 1)
                            )
                    }

                    // Actions — Cancel first and visually dominant, so the safe
                    // option is the one that falls under the thumb.
                    VStack(spacing: 12) {
                        Button(action: { isPresented = false }) {
                            Text("Cancel — keep my account")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(SL.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isDeleting)

                        Button(action: performDelete) {
                            HStack(spacing: 8) {
                                if isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "C1121F")))
                                        .scaleEffect(0.85)
                                }
                                Text(isDeleting ? "Deleting…" : "Permanently delete my account")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(canDelete ? Color(hex: "C1121F") : SL.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(canDelete ? Color(hex: "E63946").opacity(0.08) : SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(canDelete ? Color(hex: "C1121F").opacity(0.4) : SL.border, lineWidth: 1)
                            )
                        }
                        .disabled(!canDelete)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(SL.background)
            .dismissKeyboardAnyGesture()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(SL.textAccent)
                        .disabled(isDeleting)
                }
            }
        }
        .interactiveDismissDisabled(isDeleting)
    }

    private func performDelete() {
        guard canDelete else { return }
        isDeleting = true
        authManager.deleteAccount()
        // AuthManager clears local state and signs out on success, which tears
        // this sheet down with it. On failure it publishes deleteAccountError and
        // leaves the session intact — reset here so the user can retry or cancel.
        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run {
                if authManager.deleteAccountError != nil {
                    isDeleting = false
                    isPresented = false
                }
            }
        }
    }
}
