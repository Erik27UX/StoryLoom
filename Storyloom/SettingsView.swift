import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var showUpgradeForRole = false
    @State private var showImagePicker = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showDeleteConfirm = false
    @State private var avatarImage: UIImage? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar + name + Edit button
                    VStack(spacing: 12) {
                        ZStack(alignment: .bottomTrailing) {
                            // Avatar base
                            ZStack {
                                Circle()
                                    .fill(SL.surface)
                                    .frame(width: 80, height: 80)
                                    .overlay(Circle().stroke(SL.border, lineWidth: 1))

                                if let uiImg = avatarImage {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Text(String(authManager.currentUser?.name.prefix(1) ?? "U").uppercased())
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(SL.primary)
                                }
                            }

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

                    // Delete account
                    Button(action: { showDeleteConfirm = true }) {
                        Text("Delete account")
                            .font(.system(size: 14))
                            .foregroundColor(Color.red.opacity(0.7))
                    }

                    // Legal
                    Button(action: {
                        if let url = URL(string: "https://storyloom.live/privacy") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Privacy Policy")
                            .font(.system(size: 13))
                            .foregroundColor(SL.textMuted)
                    }
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(SL.background)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SL.background, for: .navigationBar)
            .task(id: authManager.currentUser?.profilePhotoURL) {
                guard let fileName = authManager.currentUser?.profilePhotoURL else {
                    avatarImage = nil
                    return
                }
                avatarImage = await Task.detached(priority: .userInitiated) {
                    ImageManager.loadImage(fileName: fileName)
                }.value
            }
        }
        .sheet(isPresented: $showImagePicker) {
            EditProfileImageSheet(isPresented: $showImagePicker, authManager: authManager)
        }
        .confirmationDialog(
            "Delete your account?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) {
                authManager.deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and all your stories. This cannot be undone.")
        }
        .alert("Couldn't delete account", isPresented: Binding(
            get: { authManager.deleteAccountError != nil },
            set: { if !$0 { authManager.deleteAccountError = nil } }
        )) {
            Button("OK", role: .cancel) { authManager.deleteAccountError = nil }
        } message: {
            Text(authManager.deleteAccountError ?? "An unknown error occurred. Please try again.")
        }
    }
}

// MARK: - Profile Image Editor

struct EditProfileImageSheet: View {
    @Binding var isPresented: Bool
    var authManager: AuthManager

    @State private var previewImage: UIImage? = nil
    @State private var currentAvatarImage: UIImage? = nil
    @State private var showCamera = false
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 24) {

            // Handle bar
            RoundedRectangle(cornerRadius: 3)
                .fill(SL.border)
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // Title
            Text("Profile photo")
                .font(SL.heading(20))
                .foregroundColor(SL.textPrimary)

            // Preview circle
            ZStack {
                Circle()
                    .fill(SL.surface)
                    .frame(width: 100, height: 100)
                    .overlay(Circle().stroke(SL.border, lineWidth: 1))

                if let img = previewImage ?? currentAvatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Text(String(authManager.currentUser?.name.prefix(1) ?? "U").uppercased())
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(SL.primary)
                }
            }

            // Pick options
            VStack(spacing: 12) {
                PhotoPickerButton(
                    label: "Choose from library",
                    icon: "photo.fill",
                    selectedImage: $previewImage
                )

                Button(action: { showCamera = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                        Text("Take a photo")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(SL.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                }
            }

            Spacer()

            // Save button — appears once an image is chosen
            if previewImage != nil {
                Button(action: savePhoto) {
                    Text(isSaving ? "Saving…" : "Save photo")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isSaving ? SL.accent.opacity(0.6) : SL.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isSaving)
            }

            Button(action: { isPresented = false }) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SL.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(SL.background.ignoresSafeArea())
        .task(id: authManager.currentUser?.profilePhotoURL) {
            guard let fileName = authManager.currentUser?.profilePhotoURL else {
                currentAvatarImage = nil
                return
            }
            currentAvatarImage = await Task.detached(priority: .userInitiated) {
                ImageManager.loadImage(fileName: fileName)
            }.value
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(selectedImage: $previewImage)
        }
    }

    private func savePhoto() {
        guard let image = previewImage else { return }
        isSaving = true
        // Capture values needed off-thread before leaving the main actor.
        let existingFileName = authManager.currentUser?.profilePhotoURL
        Task.detached(priority: .userInitiated) {
            let fileName = ImageManager.saveImage(image, existingFileName: existingFileName)
            await MainActor.run {
                authManager.updateUserProfile(
                    name: authManager.currentUser?.name ?? "",
                    birthYear: authManager.currentUser?.birthYear,
                    profilePhotoURL: fileName
                )
                isSaving = false
                isPresented = false
            }
        }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            parent.selectedImage = img
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Storyteller Settings Content

struct StorytellerSettingsContent: View {
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject private var notifManager = NotificationManager.shared
    @AppStorage("setting.commentsEnabled") private var commentsEnabled = true
    @AppStorage("setting.reactionsEnabled") private var reactionsEnabled = true
    @AppStorage("setting.questionsEnabled") private var questionsEnabled = true
    @AppStorage("setting_notifyNewReader") private var notifyNewReader = true
    @AppStorage("setting_notifyComments") private var notifyComments = true

    var body: some View {
        // Subscription card
        SectionCard(title: "Subscription") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(authManager.currentUser?.subscriptionTier.displayName ?? "Free")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                        if authManager.currentUser?.subscriptionTier == .premium || authManager.currentUser?.subscriptionTier == .family {
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
                            Text("Requires Story Legend plan")
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
                NotificationPermissionRow(notifManager: notifManager)

                HStack {
                    Text("New reader joined")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyNewReader)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                .disabled(notifManager.authorizationStatus != .authorized)
                .opacity(notifManager.authorizationStatus == .authorized ? 1 : 0.4)

                HStack {
                    Text("Comments & questions")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyComments)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                .disabled(notifManager.authorizationStatus != .authorized)
                .opacity(notifManager.authorizationStatus == .authorized ? 1 : 0.4)
            }
        }
        .task { await notifManager.refreshStatus() }
    }
}

// MARK: - Reader Settings Content

struct ReaderSettingsContent: View {
    @ObservedObject var authManager = AuthManager.shared
    @ObservedObject private var notifManager = NotificationManager.shared
    @AppStorage("setting_readerNotifyNewStory") private var notifyNewStory = true
    @AppStorage("setting_readerNotifyComments") private var notifyComments = true

    var body: some View {
        let tier = authManager.currentUser?.subscriptionTier ?? .free

        if tier == .free {
            // Free readers — upgrade CTA
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
        } else {
            // Pro / Story Legend readers — show current plan + manage button
            SectionCard(title: "Subscription") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(tier.displayName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(SL.textPrimary)
                            Text("Active")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(SL.textAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(SL.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        Text("Manage your plan")
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
        }

        // Story Vaults
        SectionCard(title: "Story Vaults") {
            NavigationLink(destination: ManageStoryVaultsView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Manage Story Vaults")
                            .font(SL.body(15))
                            .foregroundColor(SL.textPrimary)
                        Text("Remove storytellers you follow")
                            .font(SL.body(12))
                            .foregroundColor(SL.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(SL.textSecondary)
                }
            }
        }

        // Notifications
        SectionCard(title: "Notifications") {
            VStack(spacing: 12) {
                NotificationPermissionRow(notifManager: notifManager)

                HStack {
                    Text("New story available")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyNewStory)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                .disabled(notifManager.authorizationStatus != .authorized)
                .opacity(notifManager.authorizationStatus == .authorized ? 1 : 0.4)

                HStack {
                    Text("Question answered")
                        .font(SL.body(15))
                        .foregroundColor(SL.textPrimary)
                    Spacer()
                    Toggle("", isOn: $notifyComments)
                        .labelsHidden()
                        .tint(SL.accent)
                }
                .disabled(notifManager.authorizationStatus != .authorized)
                .opacity(notifManager.authorizationStatus == .authorized ? 1 : 0.4)
            }
        }
        .task { await notifManager.refreshStatus() }
    }
}

// MARK: - Notification Permission Row

struct NotificationPermissionRow: View {
    @ObservedObject var notifManager: NotificationManager

    var body: some View {
        switch notifManager.authorizationStatus {
        case .notDetermined:
            Button(action: {
                Task { await notifManager.requestPermission() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 14))
                        .foregroundColor(SL.accent)
                    Text("Enable notifications")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SL.accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(SL.textSecondary)
                }
            }
            .padding(.bottom, 4)

        case .denied:
            HStack(spacing: 8) {
                Image(systemName: "bell.slash")
                    .font(.system(size: 14))
                    .foregroundColor(SL.textSecondary)
                Text("Notifications are off")
                    .font(.system(size: 14))
                    .foregroundColor(SL.textSecondary)
                Spacer()
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(SL.accent)
            }
            .padding(.bottom, 4)

        case .authorized, .provisional, .ephemeral:
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 12))
                    .foregroundColor(SL.accent)
                Text("Notifications on")
                    .font(.system(size: 13))
                    .foregroundColor(SL.textSecondary)
            }
            .padding(.bottom, 4)

        @unknown default:
            EmptyView()
        }
    }
}

// MARK: - Reusable Components

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundColor(SL.textSecondary)

            VStack(spacing: 0) {
                content()
            }
            .padding(16)
            .background(SL.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
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
