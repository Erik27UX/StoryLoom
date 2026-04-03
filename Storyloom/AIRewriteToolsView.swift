import SwiftUI

struct AIRewriteToolsView: View {
    @Environment(\.dismiss) private var dismiss
    let originalText: String
    let onSave: (String) -> Void

    @State private var rewrittenText: String
    @State private var selectedTool: String = ""
    @State private var isProcessing = false

    init(originalText: String, onSave: @escaping (String) -> Void) {
        self.originalText = originalText
        self.onSave = onSave
        _rewrittenText = State(initialValue: originalText)
    }

    private let tools: [(icon: String, label: String, description: String)] = [
        ("scissors", "Shorten", "Make it more concise"),
        ("plus.magnifyingglass", "More detail", "Expand with more context"),
        ("waveform", "My voice", "Adjust tone to match you"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rewrite with AI")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Pick a tool to transform your story")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Tool pills
                    VStack(spacing: 10) {
                        ForEach(tools, id: \.label) { tool in
                            Button(action: {
                                selectedTool = tool.label
                                applyTool(tool.label)
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedTool == tool.label ? SL.accent.opacity(0.15) : SL.surface)
                                            .frame(width: 44, height: 44)
                                        Image(systemName: tool.icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(SL.accent)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tool.label)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(SL.textPrimary)
                                        Text(tool.description)
                                            .font(SL.body(13))
                                            .foregroundColor(SL.textSecondary)
                                    }

                                    Spacer()

                                    if selectedTool == tool.label {
                                        Image(systemName: isProcessing ? "hourglass" : "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(SL.accent)
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedTool == tool.label ? SL.surface : SL.background)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(selectedTool == tool.label ? SL.accent.opacity(0.5) : SL.border, lineWidth: 1.5)
                                )
                            }
                        }
                    }

                    // Preview
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Preview")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(0.5)
                            .textCase(.uppercase)
                            .foregroundColor(SL.textSecondary)

                        Text(rewrittenText)
                            .font(SL.serif(16))
                            .foregroundColor(SL.textPrimary)
                            .lineSpacing(6)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(SL.border, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            // Bottom buttons
            VStack(spacing: 10) {
                Button(action: {
                    onSave(rewrittenText)
                    dismiss()
                }) {
                    Text("Save changes")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(selectedTool.isEmpty ? SL.primary.opacity(0.4) : SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedTool.isEmpty)

                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(SL.border, lineWidth: 1.5)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 12)
            .background(
                SL.background
                    .shadow(color: .black.opacity(0.06), radius: 8, y: -4)
            )
        }
        .background(SL.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Close")
                    }
                    .foregroundColor(SL.accent)
                }
            }
        }
    }

    private func applyTool(_ tool: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            isProcessing = true
        }

        // Simulate AI processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            rewrittenText = mockRewrite(originalText, tool: tool)
            withAnimation(.easeInOut(duration: 0.2)) {
                isProcessing = false
            }
        }
    }

    private func mockRewrite(_ text: String, tool: String) -> String {
        switch tool {
        case "Shorten":
            let words = text.components(separatedBy: " ")
            return words.prefix(min(words.count / 2, 20)).joined(separator: " ")

        case "More detail":
            return text + " Each moment felt like an eternity of joy, creating memories we'd treasure forever."

        case "My voice":
            return text.replacingOccurrences(of: "were", with: "was").replacingOccurrences(of: "we", with: "I")

        default:
            return text
        }
    }
}

#Preview {
    NavigationStack {
        AIRewriteToolsView(
            originalText: "We wandered the Gothic Quarter for hours without a map, completely lost but completely happy.",
            onSave: { _ in }
        )
    }
}
