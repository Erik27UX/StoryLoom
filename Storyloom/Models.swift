import SwiftUI
import SwiftData
import AVFoundation
import Combine

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
final class User: Codable {
    var id: UUID
    var email: String
    var name: String
    var birthYear: Int?
    var role: UserRole
    var subscriptionTier: SubscriptionTier
    var profilePhotoURL: String?
    var dateCreated: Date

    init(email: String, name: String = "", role: UserRole = .reader) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.role = role
        self.subscriptionTier = role == .storyteller ? .premium : .free
        self.dateCreated = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, email, name, birthYear, role, subscriptionTier, profilePhotoURL, dateCreated
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        try container.encode(birthYear, forKey: .birthYear)
        try container.encode(role.rawValue, forKey: .role)
        try container.encode(subscriptionTier.rawValue, forKey: .subscriptionTier)
        try container.encode(profilePhotoURL, forKey: .profilePhotoURL)
        try container.encode(dateCreated, forKey: .dateCreated)
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.email = try container.decode(String.self, forKey: .email)
        self.name = try container.decode(String.self, forKey: .name)
        self.birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear)
        let roleString = try container.decode(String.self, forKey: .role)
        self.role = UserRole(rawValue: roleString) ?? .reader
        let tierString = try container.decode(String.self, forKey: .subscriptionTier)
        self.subscriptionTier = SubscriptionTier(rawValue: tierString) ?? .free
        self.profilePhotoURL = try container.decodeIfPresent(String.self, forKey: .profilePhotoURL)
        self.dateCreated = try container.decode(Date.self, forKey: .dateCreated)
    }
}

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
class StoryAccess {
    var id: UUID
    var storyId: UUID
    var userId: UUID
    var userEmail: String
    var accessLevel: String // "view" or "edit"
    var dateGranted: Date

    init(storyId: UUID, userEmail: String, accessLevel: String = "view") {
        self.id = UUID()
        self.storyId = storyId
        self.userId = UUID()
        self.userEmail = userEmail
        self.accessLevel = accessLevel
        self.dateGranted = Date()
    }
}

@Model
class StoryInvite {
    var id: UUID
    var storyId: UUID
    var code: String
    var expiresAt: Date
    var maxUses: Int?
    var uses: Int
    var dateCreated: Date

    init(storyId: UUID, maxUses: Int? = nil) {
        self.id = UUID()
        self.storyId = storyId
        self.code = UUID().uuidString.prefix(8).uppercased() + UUID().uuidString.prefix(4).uppercased()
        self.expiresAt = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        self.maxUses = maxUses
        self.uses = 0
        self.dateCreated = Date()
    }
}

@Model
class StoryComment {
    var id: UUID
    var storyId: UUID
    var userId: UUID
    var userName: String
    var text: String
    var dateCreated: Date

    init(storyId: UUID, userName: String, text: String) {
        self.id = UUID()
        self.storyId = storyId
        self.userId = UUID()
        self.userName = userName
        self.text = text
        self.dateCreated = Date()
    }
}

@Model
class StoryReaction {
    var id: UUID
    var storyId: UUID
    var userId: UUID
    var type: String // "heart", "like", etc
    var dateCreated: Date

    init(storyId: UUID, type: String = "heart") {
        self.id = UUID()
        self.storyId = storyId
        self.userId = UUID()
        self.type = type
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
    var hasNarration: Bool
    var publishNarration: Bool
    var narrationFileName: String?

    init(
        title: String,
        content: String,
        category: String = "Uncategorised",
        promptQuestion: String = "",
        isInVault: Bool = false,
        year: Int? = nil,
        folder: Folder? = nil,
        hasNarration: Bool = false,
        publishNarration: Bool = false,
        narrationFileName: String? = nil
    ) {
        self.title = title
        self.content = content
        self.category = category
        self.promptQuestion = promptQuestion
        self.dateCreated = Date()
        self.isInVault = isInVault
        self.year = year
        self.folder = folder
        self.hasNarration = hasNarration
        self.publishNarration = publishNarration
        self.narrationFileName = narrationFileName
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
        let loveFolder = Folder(name: "Love & Family")
        let travelFolder = Folder(name: "Travel")

        print("📁 Creating folders...")
        context.insert(childhoodFolder)
        context.insert(workFolder)
        context.insert(loveFolder)
        context.insert(travelFolder)
        print("✅ Folders created")

        // Create stories and assign to folders with years
        let entries = [
            // Work folder
            StoryEntry(
                title: "The summer I turned sixteen",
                content: "My first job was at a bakery on Elm Street. Mr. Hawthorn had hands like worn leather and a laugh you could hear from the street. He taught me that showing up early meant more than any skill you could ever learn.",
                category: "Work",
                promptQuestion: "What was your first job and what did it teach you?",
                isInVault: true,
                year: 1972,
                folder: workFolder
            ),
            StoryEntry(
                title: "The startup years",
                content: "Those three years building the company from a garage were the most exhausting and exhilarating of my life. We had no budget, all ambition, and somehow it worked.",
                category: "Work",
                promptQuestion: "What was your proudest professional achievement?",
                isInVault: true,
                year: 1995,
                folder: workFolder
            ),

            // Childhood folder
            StoryEntry(
                title: "Letters from your mother",
                content: "She wrote every Sunday without fail. Even when the news was small, the letters arrived like clockwork. I still have the box tied with twine sitting in the hall closet.",
                category: "Family",
                promptQuestion: "",
                isInVault: true,
                year: 1980,
                folder: childhoodFolder
            ),
            StoryEntry(
                title: "The tree house",
                content: "We spent entire summers in that oak tree, my brother and I. Three planks and a rope ladder was all we needed to feel like kings of the neighborhood.",
                category: "Childhood",
                promptQuestion: "What was your favorite childhood hideaway?",
                isInVault: true,
                year: 1968,
                folder: childhoodFolder
            ),

            // Love & Family folder
            StoryEntry(
                title: "How we met",
                content: "She was reading in the corner of the library, and I knocked over an entire stack of books trying to get her attention. The most embarrassing moment that turned into the best.",
                category: "Love",
                promptQuestion: "Tell me about the moment you knew you were in love",
                isInVault: true,
                year: 1985,
                folder: loveFolder
            ),
            StoryEntry(
                title: "The day our first child was born",
                content: "Waiting in that hospital room felt like time had stopped. When they placed her in my arms, everything I thought I knew about love changed in an instant.",
                category: "Family",
                promptQuestion: "What was the happiest day of your life?",
                isInVault: true,
                year: 1988,
                folder: loveFolder
            ),

            // Travel folder
            StoryEntry(
                title: "Lost in Barcelona",
                content: "We wandered the Gothic Quarter for hours without a map, completely lost but completely happy. Sometimes the best adventures are the unplanned ones.",
                category: "Adventure",
                promptQuestion: "Tell me about a travel adventure that surprised you",
                isInVault: false,
                year: 2003,
                folder: travelFolder
            ),

            // Unfiled story (no folder)
            StoryEntry(
                title: "The wisdom I wish I'd known",
                content: "If I could go back and tell my younger self anything, it would be that most of the things you worry about never happen. And the things that do happen teach you more than any planning ever could.",
                category: "Wisdom",
                promptQuestion: "What's the best advice you'd give to your younger self?",
                isInVault: true,
                year: 2020,
                folder: nil
            ),
        ]

        // Attach a sample narration to the first story (bakery)
        if let narrationStory = entries.first,
           let fileName = SampleData.createSampleNarration() {
            narrationStory.hasNarration = true
            narrationStory.narrationFileName = fileName
            narrationStory.publishNarration = true
        }

        // Stagger dates so they appear in the right order when sorted by creation date
        let timeIntervals: [TimeInterval] = [-1, -2, -3, -4, -5, -6, -7, -8]
        print("📖 Creating \(entries.count) stories...")
        for (index, entry) in entries.enumerated() {
            entry.dateCreated = Date().addingTimeInterval(TimeInterval(timeIntervals[index] * 86400))
            context.insert(entry)
            print("   - \(entry.title) (\(entry.folder?.name ?? "Unfiled"))")
        }
        print("✅ \(entries.count) stories created")
    }

    /// Generates a short 4-second audio file (spoken-style warm tone) and returns its filename.
    @discardableResult
    static func createSampleNarration() -> String? {
        let fileName = "sample_narration_demo.m4a"
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(fileName)

        // Reuse existing file
        if FileManager.default.fileExists(atPath: url.path) { return fileName }

        let sampleRate: Double = 44100
        let duration: Double = 4.0
        let totalFrames = AVAudioFrameCount(sampleRate * duration)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            return nil
        }
        buffer.frameLength = totalFrames

        let channelData = buffer.floatChannelData![0]
        // Layered tones to simulate a warm voice-like narration sample
        let tones: [(freq: Float, amp: Float)] = [(180, 0.18), (360, 0.10), (540, 0.06)]
        for i in 0..<Int(totalFrames) {
            let t = Float(i) / Float(sampleRate)
            // Fade in/out envelope
            let fade: Float = {
                let fi = t / 0.3
                let fo = (Float(duration) - t) / 0.5
                return min(1, min(fi, fo))
            }()
            var sample: Float = 0
            for tone in tones {
                sample += sin(2 * .pi * tone.freq * t) * tone.amp
            }
            channelData[i] = sample * fade
        }

        do {
            let file = try AVAudioFile(forWriting: url, settings: format.settings)
            try file.write(from: buffer)
            return fileName
        } catch {
            return nil
        }
    }
}
