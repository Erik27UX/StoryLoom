import SwiftUI

// MARK: - StoryStatusBadge
// Published vs Private indicator used on every story card and detail header.
// Distinguished three ways — icon, fill colour, and label — so it stays
// readable for colour-blind users and at a glance in a long list.

struct StoryStatusBadge: View {
    let isPublished: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPublished ? "checkmark.circle.fill" : "lock.fill")
                .font(.system(size: 10, weight: .semibold))
            Text(isPublished ? "Published" : "Private")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(isPublished ? SL.publishedText : SL.privateText)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(isPublished ? SL.publishedFill : SL.privateFill)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(
                (isPublished ? SL.publishedText : SL.privateText).opacity(0.22),
                lineWidth: 1
            )
        )
    }
}

// MARK: - CategoryFilterChips
// Horizontal scrolling folder/category filter. `nil` selection means "All".
// Shared by the storyteller's library and the reader's story list so both
// roles navigate a storyteller's folders the same way.

struct CategoryFilterChips: View {
    let folders: [Folder]
    @Binding var selection: UUID?
    /// Whether any story sits outside a folder — controls the "Unfiled" chip.
    let hasUnfiled: Bool

    /// Sentinel used for the "Unfiled" chip, distinct from nil ("All").
    static let unfiledID = UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")!

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", id: nil)
                ForEach(folders) { folder in
                    chip(title: folder.name, id: folder.id)
                }
                if hasUnfiled {
                    chip(title: "Unfiled", id: Self.unfiledID)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func chip(title: String, id: UUID?) -> some View {
        let isSelected = selection == id
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { selection = id }
        }) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .foregroundColor(isSelected ? Color(hex: "FDF9F0") : SL.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? SL.primary : SL.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : SL.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
