import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSending = false
    @State private var wasSent = false
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                        }
                        .foregroundColor(SL.accent)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reset password")
                                .font(SL.heading(28))
                                .foregroundColor(SL.textPrimary)
                            Text("Enter your email and we'll send you a link to set a new password.")
                                .font(SL.body(16))
                                .foregroundColor(SL.textSecondary)
                                .lineSpacing(4)
                        }

                        if wasSent {
                            // Success state
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(SL.accent.opacity(0.12))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "envelope.badge.checkmark.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(SL.accent)
                                }

                                VStack(spacing: 8) {
                                    Text("Check your email")
                                        .font(SL.heading(22))
                                        .foregroundColor(SL.textPrimary)
                                    Text("We sent a reset link to **\(email)**. Tap the link in the email to set a new password.")
                                        .font(SL.body(15))
                                        .foregroundColor(SL.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(4)
                                }

                                Text("Didn't get it? Check your spam folder or tap below to resend.")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                                    .multilineTextAlignment(.center)

                                Button(action: {
                                    wasSent = false
                                }) {
                                    Text("Try again")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(SL.accent)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(SL.border, lineWidth: 1))

                        } else {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email address")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SL.textSecondary)
                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .font(SL.body(16))
                                    .foregroundColor(SL.textPrimary)
                                    .padding(14)
                                    .background(SL.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                            }

                            if let error = errorMessage {
                                Text(error)
                                    .font(SL.body(14))
                                    .foregroundColor(.red)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.red.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Button(action: sendReset) {
                                HStack(spacing: 8) {
                                    if isSending {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FDF9F0")))
                                            .scaleEffect(0.85)
                                    }
                                    Text(isSending ? "Sending…" : "Send reset link")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(email.isEmpty ? SL.primary.opacity(0.5) : SL.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(email.isEmpty || isSending)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func sendReset() {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSending = true
        errorMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.client.auth.resetPasswordForEmail(
                    trimmed,
                    redirectTo: URL(string: "storyloom://auth/callback")
                )
                await MainActor.run {
                    wasSent = true
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't send the reset link. Check the email and try again."
                    isSending = false
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
