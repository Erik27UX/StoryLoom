import SwiftUI

struct AddStoryVaultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vaultLink = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {

                // Icon + heading
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(SL.accent.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 24))
                            .foregroundColor(SL.accent)
                    }

                    Text("Add Story Vault")
                        .font(SL.heading(26))
                        .foregroundColor(SL.textPrimary)

                    Text("Enter a storyteller's vault link to gain access to their stories. Ask your storyteller to share their vault link with you and paste it below.")
                        .font(SL.body(15))
                        .foregroundColor(SL.textSecondary)
                        .lineSpacing(4)
                }

                // Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vault Link")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(SL.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    TextField("Paste vault link here...", text: $vaultLink)
                        .font(SL.body(15))
                        .padding(14)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(vaultLink.isEmpty ? SL.border : SL.accent, lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        // TODO: implement vault linking backend
                        dismiss()
                    }) {
                        Text("Add Vault")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "FDF9F0"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(vaultLink.isEmpty ? SL.primary.opacity(0.4) : SL.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(vaultLink.isEmpty)

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }
                }
            }
            .padding(24)
            .background(SL.background)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AddStoryVaultView()
}
