import SwiftUI
import SwiftData
import PhotosUI

struct StoryReadyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.dateCreated, order: .reverse) var folders: [Folder]

    @ObservedObject private var audio = AudioManager.shared

    let prompt: StoryPrompt?
    let storyText: String
    let customTitle: String?

    @StateObject private var coordinator = AppCoordinator.shared

    @State private var pendingNarrationFileName: String?
    @State private var editableText: String
    @State private var selectedYear: Int? = nil
    @State private var selectedFolder: Folder? = nil
    @State private var yearText: String = ""
    @State private var selectedCategory: PromptCategory = .coreMemory
    @State private var publishNarration: Bool = true
    @State private var showConfirmation: Bool = false
    @State private var confirmedEntry: StoryEntry? = nil
    @State private var confirmedIsPublished: Bool = false

    init(
        prompt: StoryPrompt?,
        storyText: String = SampleData.sampleStoryText,
        customTitle: String? = nil,
        narrationFileName: String? = nil
    ) {
        self.prompt = prompt
        self.storyText = storyText
        self.customTitle = customTitle
        _pendingNarrationFileName = State(initialValue: narrationFileName)
        _editableText = State(initialValue: storyText)
    }

    private let imageOptions = [
        ("person.crop.square", "My photo"),
        ("xmark", "None"),
    ]
    @State private var selectedImageOption = 1  // Default: None
    @State private var pickerItem: PhotosPickerItem? = nil
    @State private var selectedUIImage: UIImage? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your story is ready")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)
                    Text("Review, add details, then publish or save")
                        .font(SL.body(16))
                        .foregroundColor(SL.textSecondary)
                }

                // Story text
                Text(editableText.isEmpty ? storyText : editableText)
                    .font(SL.serif(17))
                    .foregroundColor(SL.textPrimary)
                    .lineSpacing(7)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )

                // Image option pills
                HStack(spacing: 8) {
                    // "My photo" pill — wraps PhotosPicker
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        HStack(spacing: 6) {
                            Image(systemName: imageOptions[0].0)
                                .font(.system(size: 13))
                            Text(imageOptions[0].1)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(selectedImageOption == 0 ? SL.surface : SL.background)
                        .foregroundColor(selectedImageOption == 0 ? SL.textPrimary : SL.textSecondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedImageOption == 0 ? SL.accent : SL.border,
                                        lineWidth: selectedImageOption == 0 ? 2 : 1)
                        )
                    }

                    // "None" pill
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedImageOption = 1
                            selectedUIImage = nil
                            pickerItem = nil
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: imageOptions[1].0)
                                .font(.system(size: 13))
                            Text(imageOptions[1].1)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity)
                        .background(selectedImageOption == 1 ? SL.surface : SL.background)
                        .foregroundColor(selectedImageOption == 1 ? SL.textPrimary : SL.textSecondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedImageOption == 1 ? SL.accent : SL.border,
                                        lineWidth: selectedImageOption == 1 ? 2 : 1)
                        )
                    }
                }
                .onChange(of: pickerItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                selectedUIImage = uiImage
                                selectedImageOption = 0
                            }
                        }
                    }
                }

                // Image preview
                if let uiImage = selectedUIImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))

                        // Remove button
                        Button(action: {
                            withAnimation {
                                selectedUIImage = nil
                                selectedImageOption = 1
                                pickerItem = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 3)
                                .padding(8)
                        }
                    }
                } else if selectedImageOption == 1 {
                    // No image selected
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(SL.surface)
                            .frame(height: 90)
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                                .foregroundColor(SL.accent.opacity(0.4))
                            Text("No image")
                                .font(SL.body(12))
                                .foregroundColor(SL.textSecondary)
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                }

                // Narration section — only if user recorded
                if pendingNarrationFileName != nil || audio.isRecording {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Voice narration")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(0.5)
                            .textCase(.uppercase)
                            .foregroundColor(SL.textSecondary)

                        if audio.isRecording {
                            // Recording in progress
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                Text(audio.formatDuration(audio.recordingDuration))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SL.textPrimary)
                                    .monospacedDigit()
                                Spacer()
                                Button(action: { AudioManager.shared.stopRecording() }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "stop.fill")
                                            .font(.system(size: 12))
                                        Text("Stop")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(14)
                            .background(Color.red.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))

                        } else {
                            // Playback row
                            HStack(spacing: 12) {
                                Button(action: {
                                    guard let fileName = pendingNarrationFileName else { return }
                                    if audio.isPlaying { audio.stop() } else { audio.play(fileName: fileName) }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(SL.primary)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(SL.accent)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 3) {
                                        ForEach([0.4, 0.7, 1.0, 0.6, 0.9, 0.5, 0.8, 0.3, 0.7, 1.0, 0.5, 0.6], id: \.self) { h in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(audio.isPlaying ? SL.accent : SL.border)
                                                .frame(width: 3, height: 24 * h)
                                        }
                                    }
                                    .frame(height: 24)
                                    Text(audio.isPlaying ? "Playing…" : "Your recording")
                                        .font(SL.body(12))
                                        .foregroundColor(SL.textSecondary)
                                }

                                Spacer()

                                HStack(spacing: 8) {
                                    Button(action: {
                                        audio.stop()
                                        if let pending = pendingNarrationFileName {
                                            AudioManager.shared.deleteRecording(fileName: pending)
                                            pendingNarrationFileName = nil
                                        }
                                        publishNarration = false
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color.red.opacity(0.7))
                                            .padding(8)
                                            .background(Color.red.opacity(0.07))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.2), lineWidth: 1))
                                    }
                                    Button(action: {
                                        audio.stop()
                                        if let pending = pendingNarrationFileName {
                                            AudioManager.shared.deleteRecording(fileName: pending)
                                            pendingNarrationFileName = nil
                                        }
                                        Task {
                                            let granted = await AudioManager.shared.requestMicrophonePermission()
                                            guard granted else { return }
                                            await MainActor.run {
                                                pendingNarrationFileName = AudioManager.shared.startRecording()
                                            }
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 12))
                                            Text("Re-record")
                                                .font(.system(size: 13, weight: .medium))
                                        }
                                        .foregroundColor(SL.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(SL.background)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(SL.border, lineWidth: 1))
                                    }
                                }
                            }
                            .padding(14)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                        }

                        // Publish narration toggle
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Publish with narration")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(SL.textPrimary)
                                Text("Readers can listen to your voice")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $publishNarration)
                                .labelsHidden()
                                .tint(SL.accent)
                        }
                        .padding(14)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))
                    }
                }

                // Optional details
                VStack(alignment: .leading, spacing: 14) {
                    Text("Story details")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundColor(SL.textSecondary)

                    // Category (only for write-your-own, prompt flow already has category)
                    if prompt == nil {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category")
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                            Menu {
                                ForEach(PromptCategory.allCases.filter { $0 != .all }) { cat in
                                    Button(action: { selectedCategory = cat }) {
                                        HStack {
                                            Text(cat.rawValue)
                                            if selectedCategory == cat { Image(systemName: "checkmark") }
                                        }
                                    }
                                }
                            } label: {
                                menuLabel(icon: selectedCategory.icon, text: selectedCategory.rawValue)
                            }
                        }
                    }

                    // Year input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Year this took place")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                        HStack(spacing: 10) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(SL.textSecondary)
                            TextField("E.g., 1995", text: $yearText)
                                .font(SL.body(15))
                                .foregroundColor(SL.textPrimary)
                                .keyboardType(.numberPad)
                                .onChange(of: yearText) { newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count <= 4 {
                                        yearText = filtered
                                        selectedYear = filtered.isEmpty ? nil : Int(filtered)
                                    } else {
                                        yearText = String(filtered.prefix(4))
                                        selectedYear = Int(String(filtered.prefix(4)))
                                    }
                                }
                        }
                        .padding(12)
                        .background(SL.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
                    }

                    // Folder picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Folder")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                        Menu {
                            Button(action: { selectedFolder = nil }) {
                                HStack {
                                    Text("Unfiled")
                                    if selectedFolder == nil { Image(systemName: "checkmark") }
                                }
                            }
                            if !folders.isEmpty {
                                Divider()
                                ForEach(folders) { folder in
                                    Button(action: { selectedFolder = folder }) {
                                        HStack {
                                            Text(folder.name)
                                            if selectedFolder?.id == folder.id { Image(systemName: "checkmark") }
                                        }
                                    }
                                }
                            }
                        } label: {
                            menuLabel(icon: "folder.fill", text: selectedFolder?.name ?? "Unfiled")
                        }
                    }
                }
                .padding(16)
                .background(SL.surface.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))

                // Publish / draft
                VStack(spacing: 10) {
                    Button(action: { saveStory(publish: true) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 15))
                            Text("Publish to vault")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(showConfirmation)

                    Button(action: { saveStory(publish: false) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 15))
                            Text("Save as private")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1.5))
                    }
                    .disabled(showConfirmation)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(SL.background)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showConfirmation) {
            saveConfirmationView
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    audio.stop()
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                    }
                    .foregroundColor(SL.accent)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EditStoryView(
                    story: nil,
                    initialText: editableText,
                    onSave: { updated in editableText = updated }
                )) {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(SL.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(SL.surface)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(SL.border, lineWidth: 1))
                }
            }
        }
    }

    @ViewBuilder
    private func menuLabel(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(SL.textSecondary)
            Text(text)
                .font(SL.body(15))
                .foregroundColor(SL.textPrimary)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(SL.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SL.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
    }

    private func saveStory(publish: Bool) {
        let title = customTitle ?? deriveTitle(from: editableText)
        let category: String = {
            if let p = prompt { return p.category }
            return selectedCategory.rawValue
        }()
        let currentUser = AuthManager.shared.currentUser

        // Save image to documents if one was selected
        let savedImageFileName = selectedUIImage.flatMap { ImageManager.saveImage($0) }

        let entry = StoryEntry(
            title: title,
            content: editableText,
            category: category,
            promptQuestion: prompt?.question ?? "",
            isInVault: publish,
            year: selectedYear,
            folder: selectedFolder,
            hasNarration: pendingNarrationFileName != nil,
            publishNarration: pendingNarrationFileName != nil && publishNarration,
            narrationFileName: pendingNarrationFileName,
            imageFileName: savedImageFileName,
            authorSubscriptionTier: currentUser?.subscriptionTier ?? .free,
            authorName: currentUser?.name
        )
        modelContext.insert(entry)
        SyncManager.shared.pushStory(entry)
        confirmedEntry = entry
        confirmedIsPublished = publish
        showConfirmation = true
    }

    private func deriveTitle(from text: String) -> String {
        let sentence = text.components(separatedBy: ".").first ?? text
        let words = sentence.components(separatedBy: " ").prefix(7)
        return words.joined(separator: " ")
    }

    // MARK: - Confirmation Modal

    private var saveConfirmationView: some View {
        ZStack {
            SL.background.ignoresSafeArea()
            VStack(spacing: 0) {

                // X dismiss button
                HStack {
                    Spacer()
                    Button(action: {
                        showConfirmation = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            coordinator.returnToHome()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .padding(10)
                            .background(SL.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Checkmark + message
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(SL.accent.opacity(0.15))
                            .frame(width: 88, height: 88)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(SL.accent)
                    }

                    VStack(spacing: 8) {
                        Text(confirmedIsPublished ? "Story Published!" : "Story Saved!")
                            .font(SL.heading(24))
                            .foregroundColor(SL.textPrimary)
                        Text(confirmedIsPublished
                            ? "Your story is now shared with your readers."
                            : "Your story is saved privately. You can publish it anytime.")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        guard let entry = confirmedEntry else {
                            showConfirmation = false
                            return
                        }
                        // Dismiss the cover first, then navigate after the animation completes
                        showConfirmation = false
                        let targetId = entry.uuid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            coordinator.navigateToStory(targetId)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 15))
                            Text("View story")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: {
                        showConfirmation = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            coordinator.returnToHome()
                        }
                    }) {
                        Text("Close")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    NavigationStack {
        StoryReadyView(prompt: SampleData.prompts.first)
    }
    .modelContainer(container)
}
