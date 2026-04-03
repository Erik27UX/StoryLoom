import SwiftUI

struct UpgradeView: View {
    @ObservedObject var authManager = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: String = "pro"

    let plans: [(name: String, id: String, price: String, duration: String, features: [String], recommended: Bool)] = [
        (
            name: "Try Free",
            id: "trial",
            price: "Free",
            duration: "7 days",
            features: ["Create & record stories", "Record voice narrations", "Save as drafts"],
            recommended: false
        ),
        (
            name: "Pro",
            id: "pro",
            price: "$4.99",
            duration: "per month",
            features: ["Everything in Free", "Share with up to 50 people", "Comments & reactions", "Audio speed controls", "Priority support"],
            recommended: true
        ),
        (
            name: "Family",
            id: "family",
            price: "$9.99",
            duration: "per month",
            features: ["Everything in Pro", "Share with unlimited people", "Create team libraries", "Advanced privacy controls", "Family support"],
            recommended: false
        ),
    ]

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Become a Storyteller")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Share your stories and preserve your legacy")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Plans
                    VStack(spacing: 12) {
                        ForEach(plans, id: \.id) { plan in
                            PlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan.id,
                                onTap: { selectedPlan = plan.id }
                            )
                        }
                    }

                    // CTA buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            if selectedPlan == "trial" {
                                authManager.currentUser?.subscriptionTier = .free
                                authManager.updateUserRole(.storyteller)
                            } else {
                                // In real app, this would open payment
                                authManager.currentUser?.subscriptionTier = .premium
                                authManager.updateUserRole(.storyteller)
                            }
                            dismiss()
                        }) {
                            Text(selectedPlan == "trial" ? "Start Free Trial" : "Subscribe Now")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(SL.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: { dismiss() }) {
                            Text("Maybe later")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SL.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                        }
                    }

                    // Footer
                    VStack(spacing: 6) {
                        Text("No credit card required for free trial")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                        Text("Cancel anytime in your account settings")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
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

struct PlanCard: View {
    let plan: (name: String, id: String, price: String, duration: String, features: [String], recommended: Bool)
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(SL.textPrimary)
                        HStack(spacing: 4) {
                            Text(plan.price)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(SL.accent)
                            Text(plan.duration)
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                        }
                    }
                    Spacer()
                    if plan.recommended {
                        Text("Popular")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(SL.accent)
                            .clipShape(Capsule())
                    }
                }

                Divider()
                    .background(SL.border)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(SL.accent)
                            Text(feature)
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? SL.surface : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? SL.accent : SL.border, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    UpgradeView()
}
