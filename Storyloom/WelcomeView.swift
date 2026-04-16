import SwiftUI

struct WelcomeView: View {
    @State private var showRolePicker = false

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    // Illustration placeholder
                    ZStack {
                        Circle()
                            .fill(SL.accent.opacity(0.1))
                            .frame(width: 120, height: 120)
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(SL.accent)
                    }

                    VStack(spacing: 12) {
                        Text("Write and share your stories")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("with people you trust")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        // Mark onboarding seen — returning users won't see this screen again
                        AuthManager.shared.completeOnboarding()
                        showRolePicker = true
                    }) {
                        Text("Get started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: {
                        AuthManager.shared.completeOnboarding()
                        showRolePicker = true
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationDestination(isPresented: $showRolePicker) {
            RolePickerView()
                .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
}
