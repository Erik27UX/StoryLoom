import SwiftUI

struct ReaderActivityView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                ZStack {
                    Circle()
                        .fill(SL.surface)
                        .frame(width: 80, height: 80)
                    Image(systemName: "bell")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(SL.accent.opacity(0.6))
                }

                VStack(spacing: 8) {
                    Text("No activity yet")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(SL.textPrimary)
                    Text("When your storytellers publish new stories or reply to your questions, you'll see updates here.")
                        .font(SL.body(14))
                        .foregroundColor(SL.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(SL.background)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(SL.background, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        ReaderActivityView()
    }
}
