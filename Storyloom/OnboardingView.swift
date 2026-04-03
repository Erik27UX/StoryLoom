import SwiftUI

struct OnboardingView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var currentStep = 0

    private var steps: [(title: String, description: String, icon: String)] {
        let isReader = authManager.currentUser?.role == .reader

        if isReader {
            return [
                ("Read and listen", "Explore stories shared with you by friends and family", "book.circle.fill"),
                ("Engage and connect", "Like stories, leave comments, and dive deeper into narratives", "heart.circle.fill"),
            ]
        } else {
            return [
                ("Write or record", "Capture your stories with text or voice narration", "mic.circle.fill"),
                ("Share with care", "Invite specific people to read and listen", "person.badge.plus.fill"),
            ]
        }
    }

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentStep ? SL.accent : SL.border)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(SL.accent.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 50))
                            .foregroundColor(SL.accent)
                    }

                    VStack(spacing: 12) {
                        Text(steps[currentStep].title)
                            .font(SL.heading(26))
                            .foregroundColor(SL.textPrimary)
                        Text(steps[currentStep].description)
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: {
                        if currentStep < steps.count - 1 {
                            currentStep += 1
                        } else {
                            authManager.completeOnboarding()
                        }
                    }) {
                        Text(currentStep == steps.count - 1 ? "Get started" : "Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: { authManager.completeOnboarding() }) {
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
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
    }
}
