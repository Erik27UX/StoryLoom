import SwiftUI
import PhotosUI

// MARK: - ImageManager
// Handles saving, loading, and deleting story images to/from the local Documents directory.

enum ImageManager {

    static func imageURL(fileName: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(fileName)
    }

    static func imageExists(fileName: String?) -> Bool {
        guard let name = fileName else { return false }
        return FileManager.default.fileExists(atPath: imageURL(fileName: name).path)
    }

    /// Save a UIImage as JPEG to documents directory. Returns the new filename.
    @discardableResult
    static func saveImage(_ image: UIImage, existingFileName: String? = nil) -> String? {
        // Delete old image if replacing
        if let existing = existingFileName {
            deleteImage(fileName: existing)
        }

        guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let url = imageURL(fileName: fileName)
        do {
            try data.write(to: url)
            return fileName
        } catch {
            return nil
        }
    }

    static func deleteImage(fileName: String) {
        let url = imageURL(fileName: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    /// Load a UIImage from documents directory.
    static func loadImage(fileName: String) -> UIImage? {
        let url = imageURL(fileName: fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// A SwiftUI Image from a story's imageFileName (or nil if no image).
    static func swiftUIImage(fileName: String?) -> Image? {
        guard let name = fileName, let uiImage = loadImage(fileName: name) else { return nil }
        return Image(uiImage: uiImage)
    }
}

// MARK: - StoryImageView
// Drop-in replacement for StoryImagePlaceholder that renders real images when available.

struct StoryImageView: View {
    let story: StoryEntry
    var height: CGFloat = 120

    var body: some View {
        if let name = story.imageFileName,
           let uiImage = ImageManager.loadImage(fileName: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                .clipped()
        } else {
            StoryImagePlaceholder(story: story)
        }
    }
}

// MARK: - PhotoPickerButton
// A reusable "pick from library" button that wraps PhotosPicker.

struct PhotoPickerButton: View {
    let label: String
    let icon: String
    @Binding var selectedImage: UIImage?

    @State private var pickerItem: PhotosPickerItem? = nil

    var body: some View {
        PhotosPicker(selection: $pickerItem, matching: .images) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(SL.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(SL.surface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(SL.border, lineWidth: 1))
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run { selectedImage = uiImage }
                }
            }
        }
    }
}
