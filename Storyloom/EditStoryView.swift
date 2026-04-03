import SwiftUI
import SwiftData

struct EditStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.dateCreated, order: .reverse) var folders: [Folder]
    @ObservedObject private var audio = AudioManager.shared

    // When editing an existing story from the library
    let story: StoryEntry?
    // When editing inline from StoryReadyView before saving
    var initialText: String
    var onSave: ((String) -> Void)?
    var onDismiss: (() -> Void)?

    @State private var storyText: String
    @State private var selectedYear: Int?
    @State private var yearText: String = ""
    @State private var selectedFolder: Folder?
    @State private var publishNarration: Bool
    @State private var isVault: Bool
    @State private var pendingNarrationFileName: String? = nil

    init(
        story: StoryEntry?,
        initialText: String = "",
        onSave: ((String) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.story = story
        self.initialText = initialText
        self.onSave = onSave
        self.onDismiss = onDismiss
        _storyText = State(initialValue: story?.content ?? initialText)
        _selectedYear = State(initialValue: story?.year)
        _yearText = State(initialValue: story?.year.map(String.init) ?? "")
        _selectedFolder = State(initialValue: story?.folder)
        _publishNarration = State(initialValue: story?.publishNarration ?? false)
        _isVault = State(initialValue: story?.isInVault ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Edit your story")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Make it sound exactly like you")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Rewrite with AI button
                    NavigationLink(destination: AIRewriteToolsView(
                        originalText: storyText,
                        onSave: { rewritten in storyText = rewritten }
                    )) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 15, weight: .medium))
                            Text("Rewrite with AI")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(SL.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(SL.accent.opacity(0.5), lineWidth: 1.5)
                        )
                    }

                    // Story details (only when editing persisted story)
                    if story != nil {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Story details")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundColor(SL.textSecondary)

                            // Status toggle
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Status")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                                HStack(spacing: 10) {
                                    Button(action: { isVault = false }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "tray.fill")
                                                .font(.system(size: 13))
                                            Text("Draft")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(10)
                                        .background(isVault ? SL.background : SL.surface)
                                        .foregroundColor(isVault ? SL.textSecondary : SL.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isVault ? SL.border : SL.accent.opacity(0.6), lineWidth: isVault ? 1 : 2)
                                        )
                                    }

                                    Button(action: { isVault = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "lock.open.fill")
                                                .font(.system(size: 13))
                                            Text("Published")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(10)
                                        .background(isVault ? SL.surface : SL.background)
                                        .foregroundColor(isVault ? SL.textPrimary : SL.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isVault ? SL.accent.opacity(0.6) : SL.border, lineWidth: isVault ? 2 : 1)
                                        )
                                    }
                                }
                            }

                            // Year input
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Year")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                                HStack {
                                    Text("📅")
                                        .font(.system(size: 16))
                                    TextField("E.g., 2003", text: $yearText)
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(SL.border, lineWidth: 1)
                                )
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
                                            if selectedFolder == nil {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                    if !folders.isEmpty {
                                        Divider()
                                        ForEach(folders) { folder in
                                            Button(action: { selectedFolder = folder }) {
                                                HStack {
                                                    Text(folder.name)
                                                    if selectedFolder?.id == folder.id {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 14))
                                        Text(selectedFolder?.name ?? "Unfiled")
                                            .font(SL.body(15))
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(SL.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(SL.border, lineWidth: 1)
                                    )
                                }
                                .foregroundColor(SL.textPrimary)
                            }

                            // Voice narration section
                            narrationSection
                        }
                        .padding(16)
                        .background(SL.surface.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }

                    // Editable text
                    TextEditor(text: $storyText)
                        .font(SL.serif(17))
                        .foregroundColor(SL.textPrimary)
                        .lineSpacing(6)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .frame(minHeight: 200)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(SL.border, lineWidth: 1)
                        )

                    Button(action: saveChanges) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16))
                            Text("Save changes")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .background(SL.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: discardAndDismiss) {
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

    @ViewBuilder
    private var narrationSection: some View {
        let hasNarration = pendingNarrationFileName != nil || (story?.hasNarration ?? false)
        let playbackFileName = pendingNarrationFileName ?? story?.narrationFileName

        VStack(alignment: .leading, spacing: 10) {
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

            } else if hasNarration {
                // Playback row
                HStack(spacing: 12) {
                    Button(action: { togglePlayback(fileName: playbackFileName) }) {
                        ZStack {
                            Circle()
                                .fill(SL.primary)
                                .frame(width: 40, height: 40)
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(SL.accent)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(audio.isPlaying ? "Playing..." : (pendingNarrationFileName != nil ? "New recording" : "Your narration"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                        HStack(spacing: 3) {
                            ForEach([0.4, 0.7, 1.0, 0.6, 0.9, 0.5, 0.8, 0.3], id: \.self) { h in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(audio.isPlaying ? SL.accent : SL.border)
                                    .frame(width: 3, height: 18 * h)
                            }
                        }
                        .frame(height: 18)
                    }

                    Spacer()

                    Button(action: startRecording) {
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
                .padding(14)
                .background(SL.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))

                // Publish with narration toggle
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
                .padding(12)
                .background(SL.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.border, lineWidth: 1))

            } else {
                // No recording yet
                Button(action: startRecording) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 20))
                        Text("Record narration")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(SL.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SL.accent.opacity(0.4), lineWidth: 1.5))
                }
            }
        }
    }

    private func startRecording() {
        audio.stop()
        if let pending = pendingNarrationFileName {
            AudioManager.shared.deleteRecording(fileName: pending)
            pendingNarrationFileName = nil
        }
        Task {
            let granted = await AudioManager.shared.requestMicrophonePermission()
            guard granted else { return }
            pendingNarrationFileName = AudioManager.shared.startRecording()
        }
    }

    private func togglePlayback(fileName: String?) {
        guard let fileName else { return }
        if audio.isPlaying {
            audio.stop()
        } else {
            audio.play(fileName: fileName)
        }
    }

    private func saveChanges() {
        audio.stop()
        if let story {
            story.content = storyText
            story.year = selectedYear
            story.folder = selectedFolder
            story.isInVault = isVault
            story.publishNarration = publishNarration
            if let pending = pendingNarrationFileName {
                if let old = story.narrationFileName {
                    AudioManager.shared.deleteRecording(fileName: old)
                }
                story.narrationFileName = pending
                story.hasNarration = true
            }
        } else {
            onSave?(storyText)
        }
        onDismiss?()
        dismiss()
    }

    private func discardAndDismiss() {
        audio.stop()
        if let pending = pendingNarrationFileName {
            AudioManager.shared.deleteRecording(fileName: pending)
        }
        onDismiss?()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditStoryView(story: nil, initialText: SampleData.sampleStoryText)
    }
}
