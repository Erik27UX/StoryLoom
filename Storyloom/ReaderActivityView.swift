import SwiftUI

// The activity tab shown to Reader accounts —
// displays their reactions, comments, and questions on shared stories.
struct ReaderActivityView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Activity")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Your reactions and questions")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Loved reaction
                    ActivityCard(
                        icon: "heart.fill",
                        iconColor: SL.accent,
                        headline: "You loved a story",
                        subtext: "The summer I turned sixteen",
                        date: "2 days ago",
                        action: nil
                    )

                    // Question sent
                    ActivityCard(
                        icon: "bubble.left.fill",
                        iconColor: SL.accent,
                        headline: "You asked a question",
                        subtext: "Dad, what happened next with the car?",
                        date: "5 days ago",
                        action: nil
                    )

                    // Answer received
                    ActivityCard(
                        icon: "bubble.left.and.bubble.right.fill",
                        iconColor: Color(hex: "7A9E87"),
                        headline: "Your question was answered",
                        subtext: "Letters from your mother",
                        date: "1 day ago",
                        actionLabel: "Read the answer",
                        action: {}
                    )

                    // Divider + new question prompt
                    Rectangle()
                        .fill(SL.border)
                        .frame(height: 1)

                    Text("Ask a question")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .textCase(.uppercase)
                        .foregroundColor(SL.textSecondary)

                    Button(action: {}) {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20))
                                .foregroundColor(SL.textSecondary)
                            Text("Ask about a story you've read")
                                .font(SL.body(15))
                                .foregroundColor(SL.textSecondary)
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
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(SL.background)
        }
    }
}

struct ActivityCard: View {
    let icon: String
    let iconColor: Color
    let headline: String
    let subtext: String
    let date: String
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(headline)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(SL.textPrimary)
                    Text(date)
                        .font(SL.body(12))
                        .foregroundColor(SL.textMuted)
                }
            }

            Text(subtext)
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .italic()

            if let label = actionLabel, let action {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(SL.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(SL.border, lineWidth: 1)
                        )
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SL.border, lineWidth: 1)
        )
    }
}

#Preview {
    ReaderActivityView()
}
