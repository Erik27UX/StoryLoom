import SwiftUI

struct ReadersView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Readers")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)

                        Text("3 members reading your stories")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Avatar row
                    HStack(spacing: 16) {
                        AvatarCircle(initial: "S", bgColor: SL.surface)
                        AvatarCircle(initial: "M", bgColor: Color(hex: "D5E0CC"))
                        AvatarCircle(initial: "T", bgColor: Color(hex: "E8D5C4"))

                        Button(action: {}) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 40))
                                .foregroundColor(SL.border)
                        }
                    }

                    // Card 1 - Sarah loved your story
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16))
                                .foregroundColor(SL.accent)
                            Text("Sarah loved your story")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(SL.textPrimary)
                        }

                        Text("The summer I turned seventeen")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)

                        HStack(spacing: 10) {
                            ReactionPill(text: "Loved this")
                            ReactionPill(text: "Want more")
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )

                    // Card 2 - Mark asked a question
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 16))
                                .foregroundColor(SL.accent)
                            Text("Mark asked a question")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(SL.textPrimary)
                        }

                        Text("Dad, what happened next with the car?")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)

                        Button(action: {}) {
                            Text("Answer Mark's question")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(SL.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SL.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(SL.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )

                    // Card 3 - Invite
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 16))
                                .foregroundColor(SL.textSecondary)
                            Text("Invite more readers")
                                .font(SL.body(15))
                                .foregroundColor(SL.textSecondary)
                        }

                        Button(action: {}) {
                            Text("Share reader link")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(SL.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(SL.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(SL.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(SL.background)
        }
    }
}

struct AvatarCircle: View {
    let initial: String
    let bgColor: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(bgColor)
                .frame(width: 48, height: 48)
            Text(initial)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(SL.primary)
        }
    }
}

struct ReactionPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SL.body(12))
            .foregroundColor(SL.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(SL.background)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(SL.border, lineWidth: 1)
            )
    }
}

#Preview {
    ReadersView()
}
