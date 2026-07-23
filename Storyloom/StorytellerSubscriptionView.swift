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
                                    .foregroundColor(SL.textAccent)
                            }
                            Spacer()
                            if authManager.currentUser?.subscriptionTier == .premium || authManager.currentUser?.subscriptionTier == .family {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Active")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(SL.textAccent)
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

                        // Free plan — shown to inform, not selectable
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Free")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text("3 stories total, forever")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(SL.textSecondary)
                                }
                                Spacer()
                                if authManager.currentUser?.subscriptionTier == .free {
                                    Text("Current plan")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SL.textAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(SL.accent.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                FeatureItem("Write up to 3 stories total", included: true)
                                FeatureItem("Shareable or private", included: false)
                                FeatureItem("Voice narration", included: true)
                                FeatureItem("Questions from readers", included: false)
                            }
                        }
                        .padding(12)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))

                        // Pro plan
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pro")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text("$14.99/month")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SL.textAccent)
                                }
                                Spacer()
                                if authManager.currentUser?.subscriptionTier == .premium {
                                    Text("Current plan")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SL.textAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(SL.accent.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                FeatureItem("3 stories per day", included: true)
                                FeatureItem("Share with family (unlimited readers)", included: true)
                                FeatureItem("Voice narration", included: true)
                                FeatureItem("Questions from readers", included: false)
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
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))

                        // Story Legend plan
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Story Legend")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text("$19.99/month")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SL.textAccent)
                                }
                                Spacer()
                                if authManager.currentUser?.subscriptionTier == .family {
                                    Text("Current plan")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(SL.textAccent)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(SL.accent.opacity(0.1))
                                        .clipShape(Capsule())
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                        Text("Most features")
                                            .font(.system(size: 11, weight: .semibold))
                                    }
                                    .foregroundColor(Color(hex: "FDF9F0"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(SL.primary)
                                    .clipShape(Capsule())
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                FeatureItem("5 stories per day", included: true)
                                FeatureItem("Share with family (unlimited readers)", included: true)
                                FeatureItem("Voice narration", included: true)
                                FeatureItem("Questions from readers", included: true)
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
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.accent.opacity(0.4), lineWidth: 1.5))
                    }

                    // Management
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manage subscription")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SL.textPrimary)

                        Button(action: { openSubscriptionSettings() }) {
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

                        Button(action: { openSubscriptionSettings() }) {
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
                    .foregroundColor(SL.textAccent)
                }
            }
        }
    }

    private func openSubscriptionSettings() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
}

struct FeatureItem: View {
    let feature: String
    let included: Bool

    init(_ feature: String, included: Bool = true) {
        self.feature = feature
        self.included = included
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: included ? "checkmark" : "xmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(included ? SL.textAccent : SL.textSecondary.opacity(0.6))
            Text(feature)
                .font(SL.body(13))
                .foregroundColor(included ? SL.textPrimary : SL.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        StorytellerSubscriptionView()
    }
}
