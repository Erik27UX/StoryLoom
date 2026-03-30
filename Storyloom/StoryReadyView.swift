import SwiftUI
import SwiftData

struct StoryReadyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.navigationPath) private var navigationPath

    let prompt: StoryPrompt?
    let storyText: String

    @State private var selectedImageOption = 0
    @State private var editableText: String
    @State private var savedSuccessfully = false

    init(prompt: StoryPrompt?, storyText: String = SampleData.sampleStoryText) {
        self.prompt = prompt
        self.storyText = storyText
        _editableText = State(initialValue: storyText)
    }

    private let imageOptions = [
        ("photo.fill", "AI image"),
        ("person.crop.square", "My photo"),
        ("xmark", "None"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your story is ready")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)
                    Text("Read it, edit if you'd like, then save")
                        .font(SL.body(16))
                        .foregroundColor(SL.textSecondary)
                }

                // Story text
                Text(editableText)
                    .font(SL.serif(17))
                    .foregroundColor(SL.textPrimary)
                    .lineSpacing(6)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )

                // Image option pills
                HStack(spacing: 10) {
                    ForEach(0..<3) { i in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedImageOption = i }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: imageOptions[i].0)
                                    .font(.system(size: 14))
                                Text(imageOptions[i].1)
                                    .font(SL.body(13))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selectedImageOption == i ? SL.surface : SL.background)
                            .foregroundColor(selectedImageOption == i ? SL.textPrimary : SL.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedImageOption == i ? SL.accent : SL.border,
                                            lineWidth: selectedImageOption == i ? 2 : 1)
                            )
                        }
                    }
                }

                // Image preview
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(SL.surface)
                        .frame(height: 100)
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 28))
                        .foregroundColor(SL.accent.opacity(0.6))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(SL.border, lineWidth: 1)
                )

                // Buttons
                HStack(spacing: 12) {
                    NavigationLink(destination: EditStoryView(
                        story: nil,
                        initialText: editableText,
                        onSave: { updated in editableText = updated }
                    )) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                            Text("Edit story")
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

                    Button(action: saveStory) {
                        HStack(spacing: 6) {
                            Image(systemName: savedSuccessfully ? "checkmark.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text(savedSuccessfully ? "Saved!" : "Save")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(savedSuccessfully ? SL.accent : SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .animation(.easeInOut, value: savedSuccessfully)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
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

    private func saveStory() {
        let title = deriveTitle(from: editableText)
        let entry = StoryEntry(
            title: title,
            content: editableText,
            category: prompt?.category ?? "Uncategorised",
            promptQuestion: prompt?.question ?? "",
            isInVault: false
        )
        modelContext.insert(entry)
        withAnimation { savedSuccessfully = true }
    }

    private func deriveTitle(from text: String) -> String {
        let sentence = text.components(separatedBy: ".").first ?? text
        let words = sentence.components(separatedBy: " ").prefix(7)
        return words.joined(separator: " ")
    }
}

// SwiftUI doesn't expose navigationPath as an env value by default — this is a placeholder
private struct NavigationPathKey: EnvironmentKey {
    static let defaultValue: Binding<NavigationPath>? = nil
}
extension EnvironmentValues {
    var navigationPath: Binding<NavigationPath>? {
        get { self[NavigationPathKey.self] }
        set { self[NavigationPathKey.self] = newValue }
    }
}

#Preview {
    NavigationStack {
        StoryReadyView(prompt: SampleData.prompts.first)
    }
}
