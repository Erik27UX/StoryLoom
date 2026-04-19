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
                            // Avatar base
                            ZStack {
                                Circle()
                                    .fill(SL.surface)
                                    .frame(width: 80, height: 80)
                                    .overlay(Circle().stroke(SL.border, lineWidth: 1))

                                if let fileName = authManager.currentUser?.profilePhotoURL,
                                   let uiImg = ImageManager.loadImage(fileName: fileName) {
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
                    .padding(.bottom, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(SL.background)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SL.background, for: .navigationBar)
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

    @State private var previewImage: UIImage? = nil
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

                if let img = previewImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let fileName = authManager.currentUser?.profilePhotoURL,
                          let saved = ImageManager.loadImage(fileName: fileName) {
                    Image(uiImage: saved)
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
        .sheet(isPresented: $showCamera) {
            CameraPickerView(selectedImage: $previewImage)
        }
    }

    private func savePhoto() {
        guard let image = previewImage else { return }
        isSaving = true
        DispatchQueue.global(qos: .userInitiated).async {
            let fileName = ImageManager.saveImage(
                image,
                existingFileName: authManager.currentUser?.profilePhotoURL
            )
            DispatchQueue.main.async {
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
    @AppStorage("setting_readerNotifyNewStory") private var notifyNewStory = true
    @AppStorage("setting_readerNotifyComments") private var notifyComments = true

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
