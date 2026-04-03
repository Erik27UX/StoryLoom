import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignup = false
    @State private var name = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

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
                                Text("Full name")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                                TextField("Jane Doe", text: $name)
                                    .font(SL.body(16))
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
                        Text(isSignup ? "Create account" : "Sign in")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(email.isEmpty || password.isEmpty || (isSignup && name.isEmpty))
                    .opacity(email.isEmpty || password.isEmpty || (isSignup && name.isEmpty) ? 0.5 : 1)

                    // Toggle between signin/signup
                    HStack(spacing: 6) {
                        Text(isSignup ? "Already have an account?" : "Don't have an account?")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)
                        Button(action: { isSignup.toggle(); errorMessage = "" }) {
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
        }
    }

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
            authManager.signup(email: email, password: password, name: name, role: .reader)
        } else {
            authManager.login(email: email, password: password, role: .reader)
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
