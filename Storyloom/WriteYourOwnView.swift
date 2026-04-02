import SwiftUI
import SwiftData

struct WriteYourOwnView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isRecording = false

    private var canContinue: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your story")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Give it a title, then write or record")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Title — required
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("Title")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(SL.textPrimary)
                            Text("required")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(SL.accent)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(SL.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        TextField("Give your story a title", text: $title)
                            .font(.system(size: 17))
                            .foregroundColor(SL.textPrimary)
                            .padding(14)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(title.isEmpty ? SL.border : SL.accent.opacity(0.6), lineWidth: 1.5)
                            )
                    }

                    // Story content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Story")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(SL.textPrimary)

                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Write your story here, or tap the mic to speak it...")
                                    .font(SL.serif(16))
                                    .foregroundColor(SL.textMuted)
                                    .italic()
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                            }
                            TextEditor(text: $content)
                                .font(SL.serif(16))
                                .foregroundColor(SL.textPrimary)
                                .lineSpacing(5)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                                .frame(minHeight: 180)
                        }
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(SL.border, lineWidth: 1.5)
                        )

                        // Recording
                        VStack(spacing: 10) {
                            Text("or speak your story")
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)

                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) { isRecording.toggle() }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(isRecording ? Color(hex: "E63946").opacity(0.12) : SL.primary)
                                        .frame(width: 60, height: 60)
                                    Image(systemName: isRecording ? "waveform" : "mic.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(isRecording ? Color(hex: "E63946") : SL.accent)
                                }
                            }

                            Text(isRecording ? "Recording… tap to stop" : "Tap to record")
                                .font(SL.body(13))
                                .foregroundColor(isRecording ? Color(hex: "E63946") : SL.accent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }

            // Bottom bar — "Turn into story"
            VStack(spacing: 0) {
                NavigationLink(destination: StoryReadyView(
                    prompt: nil,
                    storyText: content.trimmingCharacters(in: .whitespaces),
                    customTitle: title.trimmingCharacters(in: .whitespaces),
                    hasRecording: isRecording
                )) {
                    Text("Turn into story")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canContinue ? SL.primary : SL.primary.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue)
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
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                    }
                    .foregroundColor(SL.accent)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WriteYourOwnView()
    }
}
