import SwiftUI

struct SettingsView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var showUpgradeForRole = false
    @State private var showImagePicker = false
    @State private var isEditingName = false
    @State private var editedName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar + name + Edit button
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(SL.surface)
                                .frame(width: 80, height: 80)
                                .overlay(Circle().stroke(SL.border, lineWidth: 1))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            Text(String(authManager.currentUser?.name.prefix(1) ?? "U").uppercased())
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(SL.primary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            Button(action: { showImagePicker = true }) {
                                ZStack {
                                    Circle()
                                        .fill(SL.accent)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(Color(hex: "FDF9F0"))
                                }
                            }
                            .offset(x: 8, y: 8)
                        }
                        .frame(width: 80, height: 80)

                        VStack(spacing: 6) {
                            if isEditingName {
                                HStack(spacing: 8) {
                                    TextField("Your name", text: $editedName)
                                        .font(SL.heading(20))
                                        .foregroundColor(SL.textPrimary)
                                        .multilineTextAlignment(.center)
                                    Button(action: {
                                        authManager.updateUserProfile(name: editedName, birthYear: authManager.currentUser?.birthYear, profilePhotoURL: authManager.currentUser?.profilePhotoURL)
                                        isEditingName = false
                                    }) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(SL.accent)
                                    }
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Text(authManager.currentUser?.name ?? "Your Name")
                                        .font(SL.heading(22))
                                        .foregroundColor(SL.textPrimary)
                                    Button(action: {
                                        editedName = authManager.currentUser?.name ?? ""
                                        isEditingName = true
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(SL.accent)
                                    }
                                }
                            }
                            Text("Visible to your readers")
                                .font(SL.body(11))
                                .foregroundColor(SL.textSecondary)
                            Text(authManager.currentUser?.email ?? "")
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Role Switch
                    SectionCard(title: "Account Type") {
                        VStack(spacing: 12) {
                            HStack {
                                Text(authManager.currentUser?.role == .storyteller ? "Storyteller" : "Reader")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(SL.textPrimary)
                                Spacer()
                            }

                            if authManager.currentUser?.role == .storyteller {
                                Button(action: { authManager.updateUserRole(.reader) }) {
                                    Text("Switch to Reader")
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
                            } else {
                                if authManager.currentUser?.subscriptionTier != .free {
                                    Button(action: { authManager.updateUserRole(.storyteller) }) {
                                        Text("Switch to Storyteller")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "FDF9F0"))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 46)
                                            .background(SL.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                } else {
                                    NavigationLink(destination: UpgradeView()) {
                                        Text("Upgrade to Storyteller")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "FDF9F0"))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 46)
                                            .background(SL.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }
                    }

                    if authManager.currentUser?.role == .storyteller {
                        StorytellerSettingsContent()
                    } else {
                        ReaderSettingsContent()
                    }

                    // Logout
                    Button(action: { authManager.logout() }) {
                        Text("Log out")
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
        .sheet(isPresented: $showImagePicker) {
            EditProfileImageSheet(isPresented: $showImagePicker, authManager: authManager)
        }
    }
}

// MARK: - Profile Image Editor

struct EditProfileImageSheet: View {
    @Binding var isPresented: Bool
    var authManager: AuthManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Update profile picture")
                    .font(SL.heading(22))
                    .foregroundColor(SL.textPrimary)

                VStack(spacing: 16) {
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 18))
                            Text("Choose from library")
                                .font(SL.body(16))
                            Spacer()
                        }
                        .foregroundColor(SL.textPrimary)
                        .padding(16)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text("Take a photo")
                                .font(SL.body(16))
                            Spacer()
                        }
                        .foregroundColor(SL.textPrimary)
                        .padding(16)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Spacer()

                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SL.border, lineWidth: 1)
                        )
                }
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Storyteller Settings Content

struct StorytellerSettingsContent: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var commentsEnabled = true
    @State private var reactionsEnabled = true
    @State private var questionsEnabled = true
    @State private var notifyNewReader = true
    @State private var notifyComments = true

    var body: some View {
        // Subscription card
        SectionCard(title: "Subscription") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(authManager.currentUser?.subscriptionTier.rawValue ?? "Free")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                        if authManager.currentUser?.subscriptionTier == .premium {
                            Text("Active")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(SL.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(SL.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    Text("Manage your storytelling plan")
                        .font(SL.body(13))
                        .foregroundColor(SL.textSecondary)
                }
                Spacer()
            }

            NavigationLink(destination: StorytellerSubscriptionView()) {
                Text("Manage plan")
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

        // Story Settings
        SectionCard(title: "Story Settings") {
            VStack(spacing: 12) {
                HStack {
                    Text("Comments enabled")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $commentsEnabled)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                HStack {
                    Text("Allow reactions")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $reactionsEnabled)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Questions from readers")
                            .font(SL.body(15))
                            .foregroundColor(authManager.currentUser?.subscriptionTier == .family ? SL.textPrimary : SL.textSecondary)
                        if authManager.currentUser?.subscriptionTier != .family {
                            Text("Requires Family plan")
                                .font(SL.body(11))
                                .foregroundColor(SL.accent)
                        }
                    }
                    Spacer()
                    if authManager.currentUser?.subscriptionTier == .family {
                        Toggle("", isOn: $questionsEnabled)
                            .labelsHidden()
                            .tint(SL.accent)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SL.textSecondary)
                    }
                }
            }
        }

        // Notifications
        SectionCard(title: "Notifications") {
            VStack(spacing: 12) {
                HStack {
                    Text("New reader joined")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyNewReader)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                HStack {
                    Text("Comments & reactions")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyComments)
                        .labelsHidden()
                        .tint(SL.accent)
                }
            }
        }
    }
}

// MARK: - Reader Settings Content

struct ReaderSettingsContent: View {
    @State private var notifyNewStory = true
    @State private var notifyComments = true

    var body: some View {
        // Upgrade CTA
        SectionCard(title: "Upgrade") {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(SL.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Become a Storyteller")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(SL.textPrimary)
                    Text("Free trial for 7 days")
                        .font(SL.body(13))
                        .foregroundColor(SL.textSecondary)
                }
            }
            NavigationLink(destination: UpgradeView()) {
                Text("Try Storyteller")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "FDF9F0"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(SL.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }

        // Audio Settings
        SectionCard(title: "Reading & Listening") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Audio playback speed")
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
                AudioSpeedSelector()
            }
        }

        // Notifications
        SectionCard(title: "Notifications") {
            VStack(spacing: 12) {
                HStack {
                    Text("New story available")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyNewStory)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                HStack {
                    Text("Comments & reactions")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyComments)
                        .labelsHidden()
                        .tint(SL.accent)
                }
            }
        }
    }
}

// MARK: - Reusable Components

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
    let authManager = AuthManager.shared
    let mockUser = User(email: "preview@test.com", name: "Preview User", role: .storyteller)
    mockUser.subscriptionTier = .family
    authManager.currentUser = mockUser
    authManager.isLoggedIn = true
    authManager.hasCompletedOnboarding = true

    return NavigationStack {
        SettingsView()
    }
    .environmentObject(authManager)
}
