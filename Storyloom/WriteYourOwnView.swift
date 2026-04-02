import SwiftUI
import SwiftData

struct WriteYourOwnView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.dateCreated, order: .reverse) private var folders: [Folder]

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: PromptCategory = .coreMemory
    @State private var yearText: String = ""
    @State private var selectedYear: Int? = nil
    @State private var selectedFolder: Folder? = nil
    @State private var showCategoryPicker = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your story")
                        .font(SL.heading(28))
                        .foregroundColor(SL.textPrimary)
                    Text("Start with a title — the rest is up to you")
                        .font(SL.body(16))
                        .foregroundColor(SL.textSecondary)
                }

                // Title — required
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Title")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(SL.textPrimary)
                        Text("required")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(SL.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(SL.accent.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    TextField("Give your story a title", text: $title)
                        .font(SL.body(16))
                        .padding(14)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(title.isEmpty ? SL.border : SL.accent.opacity(0.5), lineWidth: 1.5)
                        )
                }

                // Story content
                VStack(alignment: .leading, spacing: 8) {
                    Text("Story")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(SL.textPrimary)
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Write your story here...")
                                .font(SL.serif(16))
                                .foregroundColor(SL.textSecondary.opacity(0.6))
                                .padding(14)
                        }
                        TextEditor(text: $content)
                            .font(SL.serif(16))
                            .foregroundColor(SL.textPrimary)
                            .lineSpacing(5)
                            .scrollContentBackground(.hidden)
                            .padding(10)
                            .frame(minHeight: 160)
                    }
                    .background(SL.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(SL.border, lineWidth: 1.5)
                    )
                }

                // Optional fields
                VStack(alignment: .leading, spacing: 16) {
                    Text("Optional details")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.5)
                        .textCase(.uppercase)
                        .foregroundColor(SL.textSecondary)

                    // Category picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Category")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                        Menu {
                            ForEach(PromptCategory.allCases.filter { $0 != .all }) { cat in
                                Button(action: { selectedCategory = cat }) {
                                    HStack {
                                        Text(cat.rawValue)
                                        if selectedCategory == cat {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedCategory.icon)
                                    .font(.system(size: 14))
                                Text(selectedCategory.rawValue)
                                    .font(SL.body(15))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SL.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(SL.border, lineWidth: 1)
                            )
                            .foregroundColor(SL.textPrimary)
                        }
                    }

                    // Year input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Year this took place")
                            .font(SL.body(13))
                            .foregroundColor(SL.textSecondary)
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(SL.textSecondary)
                            TextField("E.g., 1995", text: $yearText)
                                .font(SL.body(15))
                                .keyboardType(.numberPad)
                                .onChange(of: yearText) { newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered.count <= 4 {
                                        yearText = filtered
                                        selectedYear = filtered.isEmpty ? nil : Int(filtered)
                                    } else {
                                        yearText = String(filtered.prefix(4))
                                        selectedYear = Int(String(filtered.prefix(4)))
                                    }
                                }
                        }
                        .padding(12)
                        .background(SL.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(SL.border, lineWidth: 1)
                        )
                    }

                    // Folder picker
                    if !folders.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Folder")
                                .font(SL.body(13))
                                .foregroundColor(SL.textSecondary)
                            Menu {
                                Button(action: { selectedFolder = nil }) {
                                    HStack {
                                        Text("Unfiled")
                                        if selectedFolder == nil { Image(systemName: "checkmark") }
                                    }
                                }
                                Divider()
                                ForEach(folders) { folder in
                                    Button(action: { selectedFolder = folder }) {
                                        HStack {
                                            Text(folder.name)
                                            if selectedFolder?.id == folder.id { Image(systemName: "checkmark") }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 14))
                                    Text(selectedFolder?.name ?? "Unfiled")
                                        .font(SL.body(15))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(SL.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(SL.border, lineWidth: 1)
                                )
                                .foregroundColor(SL.textPrimary)
                            }
                        }
                    }
                }
                .padding(16)
                .background(SL.surface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Save button
                Button(action: saveStory) {
                    Text("Save story")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "FDF9F0"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canSave ? SL.primary : SL.primary.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canSave)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
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
    }

    private func saveStory() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        let entry = StoryEntry(
            title: trimmedTitle,
            content: content.trimmingCharacters(in: .whitespaces),
            category: selectedCategory.rawValue,
            promptQuestion: "",
            isInVault: false,
            year: selectedYear,
            folder: selectedFolder
        )
        modelContext.insert(entry)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: StoryEntry.self, Folder.self, configurations: config)
    return NavigationStack {
        WriteYourOwnView()
    }
    .modelContainer(container)
}
