import SwiftUI

struct EditStoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storyText = SampleData.sampleStoryText

    let tools = [
        ("scissors", "Shorten"),
        ("plus.magnifyingglass", "More detail"),
        ("waveform", "My voice"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
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
                                .overlay(
                                    Capsule()
                                        .stroke(SL.border, lineWidth: 1)
                                )
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

                    // Buttons
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

                        Button(action: { dismiss() }) {
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
                            .font(.system(size: 16))
                    }
                    .foregroundColor(SL.accent)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditStoryView()
    }
}
