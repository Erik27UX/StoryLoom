import SwiftUI

struct StoryReadyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageOption = 0

    let imageOptions = [
        ("photo.fill", "AI image"),
        ("person.crop.square", "My photo"),
        ("xmark", "None"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your story is ready")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)

                    Text("Read it, edit if you'd like, then save")
                        .font(SL.body(16))
                        .foregroundColor(SL.textSecondary)
                }

                // Story text
                Text(SampleData.sampleStoryText)
                    .font(SL.serif(17))
                    .foregroundColor(SL.textPrimary)
                    .lineSpacing(6)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SL.border, lineWidth: 1)
                    )

                // Image options
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedImageOption = index
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: imageOptions[index].0)
                                    .font(.system(size: 14))
                                Text(imageOptions[index].1)
                                    .font(SL.body(13))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selectedImageOption == index ? SL.surface : SL.background)
                            .foregroundColor(selectedImageOption == index ? SL.textPrimary : SL.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedImageOption == index ? SL.accent : SL.border, lineWidth: selectedImageOption == index ? 2 : 1)
                            )
                        }
                    }
                }

                // Image preview
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(SL.surface)
                        .frame(height: 100)
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 28))
                        .foregroundColor(SL.accent.opacity(0.6))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(SL.border, lineWidth: 1)
                )

                // Buttons
                HStack(spacing: 12) {
                    NavigationLink(destination: EditStoryView()) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                            Text("Edit story")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(SL.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(SL.border, lineWidth: 1)
                        )
                    }

                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Save")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(SL.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
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

#Preview {
    NavigationStack {
        StoryReadyView()
    }
}
