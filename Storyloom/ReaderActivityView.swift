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
        .onAppear {
            // Re-apply dark text appearance every time this tab is shown.
            // The .toolbarColorScheme modifier interferes with UIKit appearance,
            // so we set it directly here instead.
            let a = UINavigationBarAppearance()
            a.configureWithOpaqueBackground()
            a.backgroundColor = UIColor(red: 0.992, green: 0.976, blue: 0.941, alpha: 1.0)
            let c = UIColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1.0)
            a.titleTextAttributes        = [.foregroundColor: c]
            a.largeTitleTextAttributes   = [.foregroundColor: c]
            UINavigationBar.appearance().standardAppearance   = a
            UINavigationBar.appearance().scrollEdgeAppearance = a
            UINavigationBar.appearance().compactAppearance    = a
        }
    }
}

#Preview {
    NavigationStack {
        ReaderActivityView()
    }
}
