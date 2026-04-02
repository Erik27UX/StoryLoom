import SwiftUI
import SwiftData

struct EditStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.dateCreated, order: .reverse) var folders: [Folder]

    // When editing an existing story from the library
    let story: StoryEntry?
    // When editing inline from StoryReadyView before saving
    var initialText: String
    var onSave: ((String) -> Void)?

    @State private var storyText: String
    @State private var selectedYear: Int?
    @State private var yearText: String = ""
    @State private var selectedFolder: Folder?

    init(story: StoryEntry?, initialText: String = "", onSave: ((String) -> Void)? = nil) {
        self.story = story
        self.initialText = initialText
        self.onSave = onSave
        _storyText = State(initialValue: story?.content ?? initialText)
        _selectedYear = State(initialValue: story?.year)
        _yearText = State(initialValue: story?.year.map(String.init) ?? "")
        _selectedFolder = State(initialValue: story?.folder)
    }

    let tools = [
        ("scissors",          "Shorten"),
        ("plus.magnifyingglass", "More detail"),
        ("waveform",          "My voice"),
    ]

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

                    // Tool pills
                    HStack(spacing: 10) {
                        ForEach(tools, id: \.1) { tool in
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: tool.0)
                                        .font(.system(size: 14))
                                    Text(tool.1)
                                        .font(SL.body(14))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(SL.surface)
                                .foregroundColor(SL.textSecondary)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(SL.border, lineWidth: 1))
                            }
                        }
                    }

                    // Story details (only when editing persisted story)
                    if story != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Story details")
                                .font(.system(size: 13, weight: .semibold))
                                .tracking(1)
                                .textCase(.uppercase)
                                .foregroundColor(SL.textSecondary)

                            // Year input
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Year")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                                HStack {
                                    Text("📅")
                                        .font(.system(size: 16))
                                    TextField("E.g., 1995", text: $yearText)
                                        .font(SL.body(15))
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
                        }
                        .padding(16)
                        .background(SL.surface.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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

                    HStack(spacing: 12) {
                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16))
                                Text("Rewrite with AI")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(SL.border, lineWidth: 1)
                            )
                        }

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

    private func saveChanges() {
        if let story {
            // Persisted story — update in SwiftData
            story.content = storyText
            story.year = selectedYear
            story.folder = selectedFolder
        } else {
            // Inline edit before saving — pass back via callback
            onSave?(storyText)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditStoryView(story: nil, initialText: SampleData.sampleStoryText)
    }
}
