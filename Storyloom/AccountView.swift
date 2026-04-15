import SwiftUI

struct AccountView: View {
    @AppStorage("userName")         private var userName         = ""
    @AppStorage("userRole")         private var userRole         = UserRole.storyteller.rawValue
    @AppStorage("subscriptionTier") private var subscriptionTier = SubscriptionTier.free.rawValue

    var isPremium: Bool { subscriptionTier == SubscriptionTier.premium.rawValue }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Avatar + name
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(SL.surface)
                                .frame(width: 80, height: 80)
                                .overlay(Circle().stroke(SL.border, lineWidth: 1))
                            Text(String(userName.prefix(1)).uppercased())
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(SL.primary)
                        }

                        Text(userName)
                            .font(SL.heading(22))
                            .foregroundColor(SL.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Role card
                    SectionCard(title: "Account type") {
                        HStack(spacing: 10) {
                            RolePill(
                                label: "Storyteller",
                                icon: "mic.fill",
                                description: "Create and share your stories",
                                isSelected: userRole == UserRole.storyteller.rawValue
                            ) { userRole = UserRole.storyteller.rawValue }

                            RolePill(
                                label: "Reader",
                                icon: "book.closed.fill",
                                description: "Browse stories shared with you",
                                isSelected: userRole == UserRole.reader.rawValue
                            ) { userRole = UserRole.reader.rawValue }
                        }

                        Text(userRole == UserRole.storyteller.rawValue
                            ? "You're recording stories for your family to read."
                            : "You're viewing stories shared with you by a family member.")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                            .padding(.top, 4)
                    }

                    // Subscription card
                    SectionCard(title: "Subscription") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(isPremium ? "Premium" : "Free plan")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(SL.textPrimary)
                                    if isPremium {
                                        Text("Active")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(SL.accent)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(SL.accent.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(isPremium
                                    ? "Unlimited stories · Vault sharing · Story Legend access"
                                    : "Up to 3 stories · No vault sharing")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                            }
                            Spacer()
                        }

                        if !isPremium {
                            Button(action: {}) {
                                Text("Upgrade \u{2014} $12/month")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "FDF9F0"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(SL.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.top, 4)
                        } else {
                            Button(action: {}) {
                                Text("Manage subscription")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SL.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(SL.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(SL.border, lineWidth: 1)
                                    )
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Story vault toggle (storytellers only)
                    if userRole == UserRole.storyteller.rawValue {
                        SectionCard(title: "Story vault") {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(SL.accent)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Shared with family")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(SL.textPrimary)
                                    Text("Stories marked for the vault are visible to your readers")
                                        .font(SL.body(13))
                                        .foregroundColor(SL.textSecondary)
                                }
                            }
                            Button(action: {}) {
                                Text("Manage vault")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SL.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(SL.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(SL.border, lineWidth: 1)
                                    )
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Sign out
                    Button(action: { AuthManager.shared.logout() }) {
                        Text("Sign out")
                            .font(.system(size: 15))
                            .foregroundColor(SL.textSecondary)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(SL.background)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Subviews

struct RolePill: View {
    let label: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? SL.primary : SL.background)
            .foregroundColor(isSelected ? Color(hex: "FDF9F0") : SL.textSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : SL.border, lineWidth: 1)
            )
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundColor(SL.textSecondary)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SL.border, lineWidth: 1)
        )
    }
}

#Preview {
    AccountView()
}
