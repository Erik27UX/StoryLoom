import SwiftUI

struct ChoosePromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: PromptCategory = .all
    @State private var selectedPrompt: StoryPrompt? = SampleData.prompts.first
    @State private var navigateToAnswer = false

    var filteredPrompts: [StoryPrompt] {
        if selectedCategory == .all {
            return SampleData.prompts
        }
        return SampleData.prompts.filter { $0.category == selectedCategory.rawValue }
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

                        Text("Pick one or tell your own story")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Category pills — negative horizontal padding breaks out of parent
                    // so pills can scroll edge-to-edge with their own inset
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(PromptCategory.allCases) { category in
                                CategoryPill(
                                    category: category,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, -20)

                    // Prompt cards
                    ForEach(filteredPrompts) { prompt in
                        PromptCard(
                            prompt: prompt,
                            isSelected: selectedPrompt == prompt
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPrompt = prompt
                            }
                        }
                    }

                    // Own story card
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20))
                                .foregroundColor(SL.textSecondary)
                            Text("Record your own story \u{2014} no prompt needed")
                                .font(SL.body(15))
                                .foregroundColor(SL.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                                .foregroundColor(SL.border)
                        )
                    }
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(prompt.question)
                    .font(SL.body(16))
                    .foregroundColor(SL.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text(prompt.category)
                        .font(SL.body(12))
                        .foregroundColor(SL.textMuted)

                    if let era = prompt.eraNote {
                        Text("·")
                            .foregroundColor(SL.textMuted)
                        Text(era)
                            .font(SL.body(12))
                            .foregroundColor(SL.accent)
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
        }
    }
}

#Preview {
    NavigationStack {
        ChoosePromptView()
    }
}
