import SwiftUI

struct ChoosePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: PromptCategory = .all
    @State private var selectedPrompt: StoryPrompt? = nil

    // Answered prompts stored as a JSON array of question strings in AppStorage.
    @AppStorage("answeredPromptQuestions") private var answeredJSON: String = "[]"

    private var answeredQuestions: Set<String> {
        (try? JSONDecoder().decode([String].self, from: Data(answeredJSON.utf8)))
            .map(Set.init) ?? []
    }

    private var displayedPrompts: [StoryPrompt] {
        DailyPromptManager.prompts(for: selectedCategory, answeredQuestions: answeredQuestions)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Choose a prompt")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)

                        Text("Fresh prompts every day — pick one or write your own")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Category pills — negative horizontal padding lets them scroll edge-to-edge
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PromptCategory.allCases) { category in
                                CategoryPill(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = category
                                        selectedPrompt = nil
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)

                    // Prompt cards
                    if displayedPrompts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(SL.textAccent)
                            Text("You've answered every prompt in this category!")
                                .font(SL.body(16))
                                .foregroundColor(SL.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                    } else {
                        ForEach(displayedPrompts) { prompt in
                            PromptCard(
                                prompt: prompt,
                                isSelected: selectedPrompt?.id == prompt.id,
                                isAnswered: answeredQuestions.contains(prompt.question)
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedPrompt = prompt
                                }
                            }
                        }
                    }

                    // Write your own — prominent card
                    NavigationLink(destination: WriteYourOwnView()) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(SL.accent.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(SL.accent)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Write your own story")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(SL.textPrimary)
                                Text("No prompt needed — start from scratch")
                                    .font(SL.body(13))
                                    .foregroundColor(SL.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(SL.textSecondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(SL.accent.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }

            // Bottom button
            VStack {
                NavigationLink(destination: AnswerView(prompt: selectedPrompt)) {
                    Text("Continue with this prompt")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedPrompt == nil)
                .opacity(selectedPrompt == nil ? 0.5 : 1)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 12)
            .background(
                SL.background
                    .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
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
                            .font(.system(size: 16))
                    }
                    .foregroundColor(SL.accent)
                }
            }
        }
        .onAppear {
            // Pre-select the first unanswered prompt for smoother UX
            if selectedPrompt == nil {
                selectedPrompt = displayedPrompts.first(where: { !answeredQuestions.contains($0.question) })
            }
        }
    }
}

struct CategoryPill: View {
    let category: PromptCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if category != .all {
                    Image(systemName: category.icon)
                        .font(.system(size: 13))
                }
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? SL.primary : SL.surface)
            .foregroundColor(isSelected ? Color(hex: "FDF9F0") : SL.textSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : SL.accent, lineWidth: 1)
            )
        }
    }
}

struct PromptCard: View {
    let prompt: StoryPrompt
    let isSelected: Bool
    let isAnswered: Bool
    let action: () -> Void

    init(prompt: StoryPrompt, isSelected: Bool, isAnswered: Bool = false, action: @escaping () -> Void) {
        self.prompt = prompt
        self.isSelected = isSelected
        self.isAnswered = isAnswered
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(prompt.question)
                        .font(SL.body(16))
                        .foregroundColor(isAnswered ? SL.textSecondary : SL.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if isAnswered {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(SL.textAccent.opacity(0.6))
                    }
                }

                HStack(spacing: 4) {
                    Text(prompt.category)
                        .font(SL.body(12))
                        .foregroundColor(SL.textSecondary)

                    if let era = prompt.eraNote {
                        Text("·")
                            .foregroundColor(SL.textSecondary)
                        Text(era)
                            .font(SL.body(12))
                            .foregroundColor(SL.textAccent)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? SL.surface : SL.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? SL.accent : SL.border, lineWidth: isSelected ? 2 : 1)
            )
            .opacity(isAnswered && !isSelected ? 0.7 : 1.0)
        }
    }
}

#Preview {
    NavigationStack {
        ChoosePromptView()
    }
}
