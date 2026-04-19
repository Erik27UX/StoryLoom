import SwiftUI

// MARK: - Story Limit Checker

struct StoryLimitChecker {
    static func isAtLimit(stories: [StoryEntry], tier: SubscriptionTier) -> Bool {
        switch tier {
        case .free:
            // Free: lifetime limit of 3 total stories
            return stories.count >= 3
        case .premium:
            // Pro: 3 per day
            let start = Calendar.current.startOfDay(for: Date())
            let todayCount = stories.filter { $0.dateCreated >= start }.count
            return todayCount >= 3
        case .family:
            // Story Legend: 5 per day
            let start = Calendar.current.startOfDay(for: Date())
            let todayCount = stories.filter { $0.dateCreated >= start }.count
            return todayCount >= 5
        }
    }

    static func tomorrowResetTime() -> String {
        let tomorrow = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: Date())
        ) ?? Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: tomorrow)
    }
}

// MARK: - Free Limit View

struct FreeLimitView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .padding(10)
                            .background(SL.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(SL.primary.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 36))
                            .foregroundColor(SL.primary)
                    }

                    VStack(spacing: 10) {
                        Text("You've reached your story limit")
                            .font(SL.heading(24))
                            .foregroundColor(SL.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("The free plan includes 3 stories. Upgrade to Pro to write 3 stories a day, or go Story Legend for 5 a day.")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: UpgradeView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 15))
                            Text("See plans")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .simultaneousGesture(TapGesture().onEnded { dismiss() })

                    Button(action: { dismiss() }) {
                        Text("Not now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Pro Limit View

struct ProLimitView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .padding(10)
                            .background(SL.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(SL.accent.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 36))
                            .foregroundColor(SL.accent)
                    }

                    VStack(spacing: 10) {
                        Text("You've reached today's limit")
                            .font(SL.heading(24))
                            .foregroundColor(SL.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("You've written 3 stories today. Your next stories unlock at \(StoryLimitChecker.tomorrowResetTime()).")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: UpgradeView()) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 15))
                            Text("Upgrade to Story Legend")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .simultaneousGesture(TapGesture().onEnded { dismiss() })

                    Button(action: { dismiss() }) {
                        Text("Got it")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Legend Limit View

struct LegendLimitView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SL.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(SL.textSecondary)
                            .padding(10)
                            .background(SL.surface)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(SL.border, lineWidth: 1))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "C17B6A").opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(hex: "C17B6A"))
                    }

                    VStack(spacing: 10) {
                        Text("You've shared 5 stories today.")
                            .font(SL.heading(24))
                            .foregroundColor(SL.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("That's no small thing. Rest the pen for now and let your readers catch up — back at it at \(StoryLimitChecker.tomorrowResetTime()).")
                            .font(SL.body(15))
                            .foregroundColor(SL.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("Got it")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
