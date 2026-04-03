import SwiftUI

struct SettingsView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            if authManager.currentUser?.role == .storyteller {
                StorytellerSettingsView()
            } else {
                ReaderSettingsView()
            }
        }
    }
}

// MARK: - Storyteller Settings

struct StorytellerSettingsView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var selectedSection = "account"

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Account")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Manage your storyteller account")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Sections
                    VStack(spacing: 0) {
                        // Account section
                        SettingsSectionHeader(title: "Account")
                        AccountSettingsItem(label: "Name", value: authManager.currentUser?.name ?? "")
                        AccountSettingsItem(label: "Email", value: authManager.currentUser?.email ?? "")
                        AccountSettingsItem(label: "Birth year", value: authManager.currentUser?.birthYear.map(String.init) ?? "Not set")

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Subscription section
                        SettingsSectionHeader(title: "Subscription")
                        NavigationLink(destination: StorytellerSubscriptionView()) {
                            HStack {
                                Text("Current plan")
                                    .font(SL.body(16))
                                    .foregroundColor(SL.textPrimary)
                                Spacer()
                                HStack(spacing: 8) {
                                    Text(authManager.currentUser?.subscriptionTier.rawValue ?? "Free")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SL.accent)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SL.textSecondary)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Story Settings
                        SettingsSectionHeader(title: "Story Settings")
                        ToggleSettingItem(label: "Comments enabled", isOn: .constant(true))
                        ToggleSettingItem(label: "Allow reactions", isOn: .constant(true))

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Notifications
                        SettingsSectionHeader(title: "Notifications")
                        ToggleSettingItem(label: "New reader joined", isOn: .constant(true))
                        ToggleSettingItem(label: "Comments & reactions", isOn: .constant(true))

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Help
                        SettingsSectionHeader(title: "Help")
                        NavigationLink(destination: Text("Contact support - Coming soon")) {
                            HStack {
                                Text("Contact support")
                                    .font(SL.body(16))
                                    .foregroundColor(SL.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Logout
                        SettingsSectionHeader(title: "")
                        Button(action: { authManager.logout() }) {
                            Text("Log out")
                                .font(SL.body(16))
                                .foregroundColor(Color.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Reader Settings

struct ReaderSettingsView: View {
    @ObservedObject var authManager = AuthManager.shared

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Account")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Manage your account")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)

                    // Sections
                    VStack(spacing: 0) {
                        // Account section
                        SettingsSectionHeader(title: "Account")
                        AccountSettingsItem(label: "Name", value: authManager.currentUser?.name ?? "")
                        AccountSettingsItem(label: "Email", value: authManager.currentUser?.email ?? "")

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Upgrade to Storyteller
                        SettingsSectionHeader(title: "Become a Storyteller")
                        NavigationLink(destination: UpgradeView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Try Storyteller")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(SL.textPrimary)
                                    Text("Free for 7 days")
                                        .font(SL.body(13))
                                        .foregroundColor(SL.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        .background(SL.accent.opacity(0.05))

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Reading & Listening
                        SettingsSectionHeader(title: "Reading & Listening")
                        Text("Audio playback speed")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                        AudioSpeedSelector()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Notifications
                        SettingsSectionHeader(title: "Notifications")
                        ToggleSettingItem(label: "New story available", isOn: .constant(true))
                        ToggleSettingItem(label: "Comments & reactions", isOn: .constant(true))

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Help
                        SettingsSectionHeader(title: "Help")
                        NavigationLink(destination: Text("Contact support - Coming soon")) {
                            HStack {
                                Text("Contact support")
                                    .font(SL.body(16))
                                    .foregroundColor(SL.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.textSecondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }

                        Divider().background(SL.border).padding(.horizontal, 20)

                        // Logout
                        SettingsSectionHeader(title: "")
                        Button(action: { authManager.logout() }) {
                            Text("Log out")
                                .font(SL.body(16))
                                .foregroundColor(Color.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsSectionHeader: View {
    let title: String

    var body: some View {
        if !title.isEmpty {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundColor(SL.textSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
    }
}

struct AccountSettingsItem: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(SL.body(16))
                .foregroundColor(SL.textPrimary)
            Spacer()
            Text(value)
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct ToggleSettingItem: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(SL.body(16))
                .foregroundColor(SL.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(SL.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct AudioSpeedSelector: View {
    @State private var selectedSpeed: Float = 1.0

    var body: some View {
        HStack(spacing: 8) {
            ForEach([0.75, 1.0, 1.25], id: \.self) { speed in
                Button(action: { selectedSpeed = Float(speed) }) {
                    Text("\(String(format: "%.2f", speed))x")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedSpeed == Float(speed) ? Color(hex: "FDF9F0") : SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selectedSpeed == Float(speed) ? SL.accent : SL.background)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
