import SwiftUI
import SwiftData

struct EditStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // When editing an existing story from the library
    let story: StoryEntry?
    // When editing inline from StoryReadyView before saving
    var initialText: String
    var onSave: ((String) -> Void)?

    @State private var storyText: String

    init(story: StoryEntry?, initialText: String = "", onSave: ((String) -> Void)? = nil) {
        self.story = story
        self.initialText = initialText
        self.onSave = onSave
        _storyText = State(initialValue: story?.content ?? initialText)
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
