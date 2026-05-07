import SwiftUI
import PhotosUI

// MARK: - ImageManager
// Handles saving, loading, and deleting story images.
// Files are stored in Application Support (not user-visible in Files app).
// Written with NSFileProtectionComplete so they are encrypted when the device is locked.

enum ImageManager {

    /// The canonical directory for story images.
    /// Application Support is not user-visible and is backed up to iCloud/iTunes,
    /// which is appropriate for user-created content.
    private static let storageDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport
    }()

    /// Returns the URL for a given image file, migrating from the old Documents
    /// location on first access if the file was saved by an earlier app version.
    static func imageURL(fileName: String) -> URL {
        let newURL = storageDirectory.appendingPathComponent(fileName)
        if !FileManager.default.fileExists(atPath: newURL.path) {
            let oldURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: oldURL.path) {
                try? FileManager.default.moveItem(at: oldURL, to: newURL)
            }
        }
        return newURL
    }

    static func imageExists(fileName: String?) -> Bool {
        guard let name = fileName else { return false }
        return FileManager.default.fileExists(atPath: imageURL(fileName: name).path)
    }

    /// Save a UIImage as JPEG to Application Support. Returns the new filename.
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
            // .completeFileProtection encrypts the file when the device is locked.
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            return fileName
        } catch {
            return nil
        }
    }

    static func deleteImage(fileName: String) {
        let url = imageURL(fileName: fileName)
        try? FileManager.default.removeItem(at: url)
    }

    /// Load a UIImage from Application Support.
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
    var height: CGFloat = 130

    var body: some View {
        if let name = story.imageFileName,
           let uiImage = ImageManager.loadImage(fileName: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
        }
        // No fallback — when no image, renders nothing (EmptyView)
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
