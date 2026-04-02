import SwiftUI
import SwiftData

// MARK: - Enums

enum UserRole: String, Codable, CaseIterable {
    case storyteller = "Storyteller"
    case reader = "Reader"
}

enum SubscriptionTier: String, Codable {
    case free = "Free"
    case premium = "Premium"
}

// MARK: - SwiftData models

@Model
class Folder {
    var id: UUID
    var name: String
    var dateCreated: Date
    @Relationship(deleteRule: .cascade, inverse: \StoryEntry.folder) var stories: [StoryEntry] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
    }
}

@Model
class StoryEntry {
    var title: String
    var content: String
    var category: String
    var promptQuestion: String
    var dateCreated: Date
    var isInVault: Bool
    var year: Int?
    var folder: Folder?

    init(
        title: String,
        content: String,
        category: String = "Uncategorised",
        promptQuestion: String = "",
        isInVault: Bool = false,
        year: Int? = nil,
        folder: Folder? = nil
    ) {
        self.title = title
        self.content = content
        self.category = category
        self.promptQuestion = promptQuestion
        self.dateCreated = Date()
        self.isInVault = isInVault
        self.year = year
        self.folder = folder
    }

    var dateFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .long
        return f.string(from: dateCreated)
    }

    var preview: String {
        let words = content.components(separatedBy: " ")
        if words.count > 22 {
            return words.prefix(22).joined(separator: " ") + "..."
        }
        return content
    }
}

// MARK: - Prompt / category (non-persisted)

struct StoryPrompt: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let category: String
    let eraNote: String?

    static func == (lhs: StoryPrompt, rhs: StoryPrompt) -> Bool { lhs.id == rhs.id }
}

enum PromptCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case coreMemory = "Core Memory"
    case love = "Love"
    case work = "Work"
    case family = "Family"
    case money = "Money"
    case adventure = "Adventure"
    case childhood = "Childhood"
    case wisdom = "Wisdom"
    case home = "Home"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:        return "line.3.horizontal.decrease.circle"
        case .coreMemory: return "star.fill"
        case .love:       return "heart.fill"
        case .work:       return "briefcase.fill"
        case .family:     return "person.2.fill"
        case .money:      return "dollarsign.circle"
        case .adventure:  return "airplane"
        case .childhood:  return "house.fill"
        case .wisdom:     return "lightbulb.fill"
        case .home:       return "building.2.fill"
        }
    }
}

// MARK: - Static sample data (used for seeding and prompts)

struct SampleData {
    static let prompts: [StoryPrompt] = [
        StoryPrompt(
            question: "What was your first job and what did it teach you?",
            category: "Work",
            eraNote: "matched to your 1960s"
        ),
        StoryPrompt(
            question: "Describe the street you grew up on \u{2014} what do you still smell or hear when you think of it?",
            category: "Childhood",
            eraNote: "your 1960s"
        ),
        StoryPrompt(
            question: "What was the best piece of advice you ever gave someone?",
            category: "Wisdom",
            eraNote: nil
        ),
        StoryPrompt(
            question: "Tell me about the moment you knew you were in love.",
            category: "Love",
            eraNote: nil
        ),
    ]

    static let sampleStoryText = "My first job was at a bakery on Elm Street, the summer I turned sixteen. Mr. Hawthorn had hands like worn leather and a laugh you could hear from the street. He taught me that showing up early meant more than any skill you could ever learn later in life."

    static func seedStories(in context: ModelContext) {
        // Create sample folders
        let childhoodFolder = Folder(name: "Childhood")
        let workFolder = Folder(name: "Work")

        context.insert(childhoodFolder)
        context.insert(workFolder)

        // Create stories and assign to folders
        let entries = [
            StoryEntry(
                title: "The summer I turned sixteen",
                content: sampleStoryText,
                category: "Work",
                promptQuestion: "What was your first job and what did it teach you?",
                isInVault: true,
                year: 1972,
                folder: workFolder
            ),
            StoryEntry(
                title: "Letters from your mother",
                content: "She wrote every Sunday without fail. Even when the news was small, the letters arrived like clockwork. I still have the box tied with twine sitting in the hall closet.",
                category: "Family",
                promptQuestion: "",
                isInVault: true,
                year: 1980,
                folder: childhoodFolder
            ),
        ]

        // Stagger dates so they appear in the right order
        entries[0].dateCreated = Date().addingTimeInterval(-3 * 86400)
        entries[1].dateCreated = Date().addingTimeInterval(-6 * 86400)
        entries.forEach { context.insert($0) }
    }
}
