import SwiftUI

struct RolePickerView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var selectedRole: UserRole?
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What would you like to do?")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)
                    Text("You can change this later anytime")
                        .font(SL.body(16))
                        .foregroundColor(SL.textSecondary)
                }

                VStack(spacing: 12) {
                    // Storyteller option
                    Button(action: { selectedRole = .storyteller }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(SL.accent)
                                    Text("Write my stories")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                }
                                Text("Record and share your memories")
                                    .font(SL.body(14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            Spacer()
                            Image(systemName: selectedRole == .storyteller ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(selectedRole == .storyteller ? SL.accent : SL.textSecondary)
                        }
                        .padding(16)
                        .background(selectedRole == .storyteller ? SL.surface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedRole == .storyteller ? SL.accent : SL.border, lineWidth: selectedRole == .storyteller ? 2 : 1)
                        )
                    }

                    // Reader option
                    Button(action: { selectedRole = .reader }) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "book.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(SL.accent)
                                    Text("Read stories")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                }
                                Text("Listen and read stories from others")
                                    .font(SL.body(14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            Spacer()
                            Image(systemName: selectedRole == .reader ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24))
                                .foregroundColor(selectedRole == .reader ? SL.accent : SL.textSecondary)
                        }
                        .padding(16)
                        .background(selectedRole == .reader ? SL.surface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedRole == .reader ? SL.accent : SL.border, lineWidth: selectedRole == .reader ? 2 : 1)
                        )
                    }
                }

                Spacer()

                Button(action: {
                    if let role = selectedRole {
                        authManager.updateUserRole(role)
                        showOnboarding = true
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(selectedRole != nil ? SL.primary : SL.primary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedRole == nil)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .navigationDestination(isPresented: $showOnboarding) {
            OnboardingView()
                .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    NavigationStack {
        RolePickerView()
    }
}
