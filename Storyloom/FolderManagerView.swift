import SwiftUI
import SwiftData

struct FolderManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]

    @State private var newFolderName: String = ""
    @State private var folderToDelete: Folder? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Manage folders")
                            .font(SL.heading(28))
                            .foregroundColor(SL.textPrimary)
                        Text("Organize your stories")
                            .font(SL.body(16))
                            .foregroundColor(SL.textSecondary)
                    }

                    // Create folder section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Create folder")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundColor(SL.textSecondary)

                        HStack(spacing: 12) {
                            TextField("Folder name", text: $newFolderName)
                                .font(SL.body(15))
                                .padding(12)
                                .background(SL.background)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(SL.border, lineWidth: 1)
                                )

                            Button(action: createFolder) {
                                Text("Create")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color(hex: "FDF9F0"))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(SL.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
                            .opacity(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                        }
                    }

                    // Folders list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your folders")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(1)
                            .textCase(.uppercase)
                            .foregroundColor(SL.textSecondary)

                        if folders.isEmpty {
                            Text("No folders yet. Create one to organize your stories.")
                                .font(SL.body(14))
                                .foregroundColor(SL.textSecondary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            ForEach(folders) { folder in
                                FolderRow(
                                    folder: folder,
                                    onDelete: {
                                        folderToDelete = folder
                                        showDeleteConfirmation = true
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
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
                        }
                        .foregroundColor(SL.accent)
                    }
                }
            }
            .confirmationDialog(
                "Delete folder?",
                isPresented: $showDeleteConfirmation,
                presenting: folderToDelete
            ) { folder in
                Button("Delete", role: .destructive) {
                    deleteFolder(folder)
                }
                Button("Cancel", role: .cancel) {}
            } message: { folder in
                Text("Stories in \"\(folder.name)\" will move to Unfiled. This cannot be undone.")
            }
        }
    }

    private func createFolder() {
        let trimmed = newFolderName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let folder = Folder(name: trimmed)
        modelContext.insert(folder)
        // Push to Supabase
        SyncManager.shared.pushFolder(folder)
        newFolderName = ""
    }

    private func deleteFolder(_ folder: Folder) {
        // Delete from Supabase (stories move to Unfiled via ON DELETE SET NULL)
        SyncManager.shared.deleteFolder(id: folder.id)
        modelContext.delete(folder)
    }
}

struct FolderRow: View {
    let folder: Folder
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(SL.textPrimary)
                Text("\(folder.stories.count) stories")
                    .font(SL.body(13))
                    .foregroundColor(SL.textSecondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "E63946"))
                    .padding(8)
                    .background(Color(hex: "E63946").opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(SL.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(SL.border, lineWidth: 1)
        )
    }
}

#Preview {
    FolderManagerView()
        .modelContainer(for: Folder.self, inMemory: true)
}
