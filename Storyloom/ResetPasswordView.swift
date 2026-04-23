import SwiftUI

struct ResetPasswordView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var isUpdating = false
    @State private var isSuccess = false
    @State private var errorMessage: String? = nil

    private var passwordsMatch: Bool { newPassword == confirmPassword }
    private var isValid: Bool { newPassword.count >= 6 && passwordsMatch && !confirmPassword.isEmpty }

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New password")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Choose a new password for your Storyloom account.")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                            .lineSpacing(4)
                    }

                    if isSuccess {
                        // Success state
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(SL.accent.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(SL.accent)
                            }

                            VStack(spacing: 8) {
                                Text("Password updated!")
                                    .font(SL.heading(22))
                                    .foregroundColor(SL.textPrimary)
                                Text("Your password has been changed. You're all set.")
                                    .font(SL.body(15))
                                    .foregroundColor(SL.textSecondary)
                                    .multilineTextAlignment(.center)
                            }

                            Button(action: {
                                AuthManager.shared.isPasswordRecovery = false
                            }) {
                                Text("Continue to Storyloom")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "FDF9F0"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(SL.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SL.border, lineWidth: 1))

                    } else {
                        // Password fields
                        VStack(spacing: 16) {

                            // New password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("New password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SL.textSecondary)
                                HStack {
                                    Group {
                                        if showPassword {
                                            TextField("At least 6 characters", text: $newPassword)
                                        } else {
                                            SecureField("At least 6 characters", text: $newPassword)
                                        }
                                    }
                                    .font(SL.body(16))
                                    .foregroundColor(SL.textPrimary)

                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .font(.system(size: 15))
                                            .foregroundColor(SL.textSecondary)
                                    }
                                }
                                .padding(14)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                            }

                            // Confirm password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(SL.textSecondary)
                                SecureField("Same password again", text: $confirmPassword)
                                    .font(SL.body(16))
                                    .foregroundColor(SL.textPrimary)
                                    .padding(14)
                                    .background(SL.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12).stroke(
                                            !confirmPassword.isEmpty && !passwordsMatch
                                                ? Color.red.opacity(0.5) : SL.border,
                                            lineWidth: 1
                                        )
                                    )
                                if !confirmPassword.isEmpty && !passwordsMatch {
                                    Text("Passwords don't match")
                                        .font(SL.body(13))
                                        .foregroundColor(.red)
                                }
                            }
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

                        Button(action: updatePassword) {
                            HStack(spacing: 8) {
                                if isUpdating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FDF9F0")))
                                        .scaleEffect(0.85)
                                }
                                Text(isUpdating ? "Updating…" : "Update password")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isValid ? SL.primary : SL.primary.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!isValid || isUpdating)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    private func updatePassword() {
        guard isValid else { return }
        isUpdating = true
        errorMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.client.auth.update(
                    user: UserAttributes(password: newPassword)
                )
                await MainActor.run {
                    isSuccess = true
                    isUpdating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Couldn't update password. Please try again."
                    isUpdating = false
                }
            }
        }
    }
}

#Preview {
    ResetPasswordView()
}
