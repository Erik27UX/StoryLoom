import SwiftUI

struct StorytellerSubscriptionView: View {
    @ObservedObject var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Current plan info
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current plan")
                                    .font(.system(size: 13, weight: .semibold))
                                    .tracking(1)
                                    .textCase(.uppercase)
                                    .foregroundColor(SL.textSecondary)
                                Text(authManager.currentUser?.subscriptionTier.displayName ?? "Free")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(SL.accent)
                            }
                            Spacer()
                            if authManager.currentUser?.subscriptionTier == .premium || authManager.currentUser?.subscriptionTier == .family {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Active")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(SL.accent)
                            }
                        }
                    }
                    .padding(16)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Plans comparison
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose your plan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SL.textPrimary)

                        // Pro plan
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pro")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text("$4.99/month")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SL.accent)
                                }
                                Spacer()
                                if authManager.currentUser?.subscriptionTier == .premium {
                                    Text("Current plan")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SL.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(SL.accent.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                FeatureItem("Share with up to 50 people")
                                FeatureItem("Comments & reactions")
                                FeatureItem("Audio speed controls")
                                FeatureItem("Priority support")
                            }
                            if authManager.currentUser?.subscriptionTier != .premium {
                                NavigationLink(destination: UpgradeView()) {
                                    Text("Select Pro")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "FDF9F0"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(SL.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(12)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Story Legend plan
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Story Legend")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text("$9.99/month")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SL.accent)
                                }
                                Spacer()
                                if authManager.currentUser?.subscriptionTier == .family {
                                    Text("Current plan")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SL.accent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(SL.accent.opacity(0.1))
                                        .clipShape(Capsule())
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                        Text("Best value")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(Color(hex: "FDF9F0"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .clipShape(Capsule())
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                FeatureItem("Share with unlimited people")
                                FeatureItem("Create team libraries")
                                FeatureItem("Advanced privacy controls")
                                FeatureItem("Story Legend support")
                            }
                            if authManager.currentUser?.subscriptionTier != .family {
                                NavigationLink(destination: UpgradeView()) {
                                    Text("Select Story Legend")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: "FDF9F0"))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(SL.primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(12)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Management
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manage subscription")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SL.textPrimary)

                        Button(action: {}) {
                            HStack {
                                Text("Update payment method")
                                    .font(SL.body(15))
                                    .foregroundColor(SL.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            .padding(12)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: {}) {
                            HStack {
                                Text("Cancel subscription")
                                    .font(SL.body(15))
                                    .foregroundColor(Color.red)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            .padding(12)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                    }
                    .foregroundColor(SL.accent)
                }
            }
        }
    }
}

struct FeatureItem: View {
    let feature: String

    init(_ feature: String) {
        self.feature = feature
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(SL.accent)
            Text(feature)
                .font(SL.body(13))
                .foregroundColor(SL.textPrimary)
        }
    }
}

#Preview {
    StorytellerSubscriptionView()
}
