import Foundation

struct StoryPrompt: Identifiable, Equatable {
    let id = UUID()
    let question: String
    let category: String
    let eraNote: String?

    static func == (lhs: StoryPrompt, rhs: StoryPrompt) -> Bool {
        lhs.id == rhs.id
    }
}

struct Story: Identifiable {
    let id = UUID()
    let title: String
    let preview: String
    let date: String
    let fullText: String
}

struct FamilyMember: Identifiable {
    let id = UUID()
    let initial: String
    let color: String
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
        case .all: return "line.3.horizontal.decrease.circle"
        case .coreMemory: return "star.fill"
        case .love: return "heart.fill"
        case .work: return "briefcase.fill"
        case .family: return "person.2.fill"
        case .money: return "dollarsign.circle"
        case .adventure: return "airplane"
        case .childhood: return "house.fill"
        case .wisdom: return "lightbulb.fill"
        case .home: return "building.2.fill"
        }
    }
}

// MARK: - Sample Data

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

    static let stories: [Story] = [
        Story(
            title: "The summer I turned sixteen",
            preview: "My first job was at a bakery on Elm Street. Mr. Hawthorn had hands like worn leather and a laugh you could hear from the street...",
            date: "March 28, 2026",
            fullText: "My first job was at a bakery on Elm Street, the summer I turned sixteen. Mr. Hawthorn had hands like worn leather and a laugh you could hear from the street. He taught me that showing up early meant more than any skill you could ever learn later in life."
        ),
        Story(
            title: "Letters from your mother",
            preview: "She wrote every Sunday without fail. Even when the news was small, the letters arrived like clockwork...",
            date: "March 25, 2026",
            fullText: "She wrote every Sunday without fail. Even when the news was small, the letters arrived like clockwork. I still have the box tied with twine sitting in the hall closet."
        ),
    ]

    static let sampleStoryText = "My first job was at a bakery on Elm Street, the summer I turned sixteen. Mr. Hawthorn had hands like worn leather and a laugh you could hear from the street. He taught me that showing up early meant more than any skill you could ever learn later in life."

    static let familyMembers: [FamilyMember] = [
        FamilyMember(initial: "S", color: "champagne"),
        FamilyMember(initial: "M", color: "sage"),
        FamilyMember(initial: "T", color: "warm"),
    ]
}
