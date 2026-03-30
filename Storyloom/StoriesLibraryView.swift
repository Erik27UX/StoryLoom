import SwiftUI

struct StoriesLibraryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your stories")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)

                    // Story cards
                    ForEach(SampleData.stories) { story in
                        StoryLibraryCard(story: story)
                    }

                    // Locked card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SL.primary)
                                .frame(width: 44, height: 44)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "FDF9F0"))
                        }

                        Text("More stories waiting")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(SL.textPrimary)

                        Text("Upgrade to unlock and share with family")
                            .font(SL.body(14))
                            .foregroundColor(SL.textSecondary)

                        Button(action: {}) {
                            Text("Unlock \u{2014} $12/month")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "FDF9F0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(SL.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(SL.surface.opacity(0.7))
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

struct StoryLibraryCard: View {
    let story: Story

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(SL.accent.opacity(0.15))
                    .frame(height: 80)
                Image(systemName: "photo.fill")
                    .font(.system(size: 24))
                    .foregroundColor(SL.accent.opacity(0.4))
            }

            Text(story.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(SL.textPrimary)

            Text(story.preview)
                .font(SL.body(14))
                .foregroundColor(SL.textSecondary)
                .lineLimit(2)

            HStack {
                Text(story.date)
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
                Spacer()
                NavigationLink(destination: EditStoryView()) {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                        Text("Edit")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "FDF9F0"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(SL.primary)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(SL.border, lineWidth: 1)
        )
    }
}

#Preview {
    StoriesLibraryView()
}
