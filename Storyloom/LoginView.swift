import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignup = false
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showEmailConfirmation = false
    @State private var confirmedEmail = ""

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !(isSignup && name.isEmpty) && !isLoading
    }

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            if showEmailConfirmation {
                emailConfirmationView
            } else {
                formView
            }
        }
    }

    // MARK: - Email Confirmation Screen

    private var emailConfirmationView: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(SL.accent.opacity(0.12))
                    .frame(width: 90, height: 90)
                Image(systemName: "envelope.fill")
                    .font(.system(size: 38))
                    .foregroundColor(SL.accent)
            }

            VStack(spacing: 12) {
                Text("Check your inbox")
                    .font(SL.heading(26))
                    .foregroundColor(SL.textPrimary)

                Text("We sent a confirmation link to")
                    .font(SL.body(16))
                    .foregroundColor(SL.textSecondary)

                Text(confirmedEmail)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(SL.textPrimary)

                Text("Tap the link in the email to activate your account. You'll be signed in automatically once confirmed.")
                    .font(SL.body(14))
                    .foregroundColor(SL.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: {
                showEmailConfirmation = false
                isSignup = false
                email = ""
                password = ""
                name = ""
            }) {
                Text("Back to sign in")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "FDF9F0"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(SL.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Login / Signup Form

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(isSignup ? "Create your account" : "Welcome back")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)
                    Text(isSignup ? "Tell us a bit about yourself" : "Sign in to continue")
                        .font(SL.body(16))
                        .foregroundColor(SL.textSecondary)
                }

                    // Form fields
                    VStack(alignment: .leading, spacing: 14) {
                        if isSignup {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("First name")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                                TextField("Jane", text: $name)
                                    .font(SL.body(16))
                                    .foregroundColor(SL.textPrimary)
                                    .padding(12)
                                    .background(SL.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                            TextField("you@example.com", text: $email)
                                .font(SL.body(16))
                                .foregroundColor(SL.textPrimary)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(12)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                            SecureField("••••••••", text: $password)
                                .font(SL.body(16))
                                .foregroundColor(SL.textPrimary)
                                .padding(12)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                        }
                    }

                    // Error message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(SL.body(13))
                            .foregroundColor(Color.red)
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Submit button
                    Button(action: submit) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FDF9F0")))
                                    .scaleEffect(0.85)
                            }
                            Text(isLoading ? "Please wait…" : (isSignup ? "Create account" : "Sign in"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "FDF9F0"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .opacity(canSubmit ? 1 : 0.5)
                    }
                    .disabled(!canSubmit)

                    // Toggle between signin/signup
                    HStack(spacing: 6) {
                        Text(isSignup ? "Already have an account?" : "Don't have an account?")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)
                        Button(action: {
                            isSignup.toggle()
                            errorMessage = ""
                        }) {
                            Text(isSignup ? "Sign in" : "Create one")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(SL.accent)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
    }  // end formView

    // MARK: - Submit

    private func submit() {
        errorMessage = ""

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        if isSignup {
            guard !name.isEmpty else {
                errorMessage = "Please enter your name"
                return
            }
        }

        isLoading = true
        Task {
            do {
                if isSignup {
                    try await authManager.signup(email: email, password: password, name: name)
                    await MainActor.run {
                        confirmedEmail = email
                        showEmailConfirmation = true
                        isLoading = false
                    }
                } else {
                    try await authManager.login(email: email, password: password)
                    // Auth state listener handles setting isLoggedIn
                }
            } catch {
                await MainActor.run {
                    errorMessage = friendlyError(error)
                    isLoading = false
                }
            }
        }
    }

    // MARK: - Error Formatting

    private func friendlyError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()

        if message.contains("invalid login credentials") || message.contains("invalid_credentials") {
            return "Email or password is incorrect"
        } else if message.contains("email already") || message.contains("already registered") {
            return "This email is already registered. Sign in instead."
        } else if message.contains("rate limit") {
            return "Too many attempts. Wait a moment and try again."
        } else if message.contains("network") || message.contains("connection") {
            return "Check your internet connection"
        } else if message.contains("password") {
            return "Password must be at least 6 characters"
        } else if message.contains("unable to validate email") || message.contains("invalid email") {
            return "Enter a valid email address"
        } else if message.contains("user") {
            return "Account not found"
        }
        return "Something went wrong. Try again."
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
