import SwiftUI

struct AnswerView: View {
    @Environment(\.dismiss) private var dismiss
    let prompt: StoryPrompt?
    @State private var answerText = ""
    @State private var isRecording = false

    // For the prototype the "generated" story is the sample text;
    // swap this out for a real AI call later.
    private var generatedStory: String { SampleData.sampleStoryText }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Prompt card
                    if let prompt {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(SL.accent)
                                Text("Your prompt")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1)
                                    .textCase(.uppercase)
                                    .foregroundColor(SL.accent)
                            }
                            Text(prompt.question)
                                .font(SL.serifMedium(18))
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Text editor
                    ZStack(alignment: .topLeading) {
                        if answerText.isEmpty {
                            Text("Type your answer here, or tap the microphone to speak...")
                                .font(SL.body(16))
                                .foregroundColor(SL.textMuted)
                                .italic()
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                        }
                        TextEditor(text: $answerText)
                            .font(SL.body(16))
                            .foregroundColor(SL.textPrimary)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .frame(minHeight: 100)
                    }
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )

                    // Voice section
                    VStack(spacing: 12) {
                        Text("or speak your answer")
                            .font(SL.body(13))
                            .foregroundColor(SL.textMuted)

                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { isRecording.toggle() }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(SL.primary)
                                    .frame(width: 56, height: 56)
                                Image(systemName: isRecording ? "waveform" : "mic.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(SL.accent)
                            }
                        }

                        Text(isRecording ? "Recording..." : "Tap to record")
                            .font(SL.body(13))
                            .foregroundColor(SL.accent)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            // Bottom button — passes prompt + generated story forward
            VStack {
                NavigationLink(destination: StoryReadyView(
                    prompt: prompt,
                    storyText: generatedStory
                )) {
                    Text("Turn into a story")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
        AnswerView(prompt: SampleData.prompts.first)
    }
}
