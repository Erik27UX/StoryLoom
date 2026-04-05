import Foundation

// MARK: - Supabase Row Models
// Codable structs that mirror the database schema exactly.
// Used for encoding (upsert/insert) and decoding (fetch).

// MARK: Profile

struct SupabaseProfile: Codable {
    let id: UUID
    let email: String?
    let name: String?
    let birthYear: Int?
    let role: String
    let subscriptionTier: String?
    let profilePhotoURL: String?

    enum CodingKeys: String, CodingKey {
        case id, email, name
        case birthYear       = "birth_year"
        case role
        case subscriptionTier = "subscription_tier"
        case profilePhotoURL  = "profile_photo_url"
    }
}

// MARK: Folder

struct SupabaseFolder: Codable {
    let id: UUID
    let ownerId: UUID
    let name: String
    let dateCreated: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId    = "owner_id"
        case name
        case dateCreated = "date_created"
    }

    init(id: UUID, ownerId: UUID, name: String, dateCreated: Date = Date()) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.dateCreated = dateCreated
    }
}

// MARK: Story

struct SupabaseStory: Codable {
    let id: UUID
    let ownerId: UUID
    let folderId: UUID?
    let title: String
    let content: String
    let category: String
    let promptQuestion: String?
    let isPublished: Bool
    let year: Int?
    let hasNarration: Bool
    let publishNarration: Bool
    let narrationFileName: String?
    let authorSubscriptionTier: String?
    let authorName: String?
    let likeCount: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId             = "owner_id"
        case folderId            = "folder_id"
        case title, content, category
        case promptQuestion      = "prompt_question"
        case isPublished         = "is_published"
        case year
        case hasNarration        = "has_narration"
        case publishNarration    = "publish_narration"
        case narrationFileName   = "narration_file_name"
        case authorSubscriptionTier = "author_subscription_tier"
        case authorName          = "author_name"
        case likeCount           = "like_count"
        case createdAt           = "created_at"
    }

    init(from story: StoryEntry, ownerId: UUID) {
        self.id                   = story.uuid
        self.ownerId              = ownerId
        self.folderId             = story.folder?.id
        self.title                = story.title
        self.content              = story.content
        self.category             = story.category
        self.promptQuestion       = story.promptQuestion.isEmpty ? nil : story.promptQuestion
        self.isPublished          = story.isInVault
        self.year                 = story.year
        self.hasNarration         = story.hasNarration
        self.publishNarration     = story.publishNarration
        self.narrationFileName    = story.narrationFileName
        self.authorSubscriptionTier = story.authorSubscriptionTier.rawValue
        self.authorName           = story.authorName
        self.likeCount            = story.likeCount
        self.createdAt            = story.dateCreated
    }
}

// MARK: Comment

struct SupabaseComment: Codable {
    let id: UUID
    let storyId: UUID
    let userId: UUID
    let userName: String
    let text: String
    let parentCommentId: UUID?
    let replyToUserName: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storyId           = "story_id"
        case userId            = "user_id"
        case userName          = "user_name"
        case text
        case parentCommentId   = "parent_comment_id"
        case replyToUserName   = "reply_to_user_name"
        case createdAt         = "created_at"
    }

    init(from comment: StoryComment, userId: UUID) {
        self.id               = comment.id
        self.storyId          = comment.storyId
        self.userId           = userId
        self.userName         = comment.userName
        self.text             = comment.text
        self.parentCommentId  = comment.parentCommentId
        self.replyToUserName  = comment.replyToUserName
        self.createdAt        = comment.dateCreated
    }
}

// MARK: Question

struct SupabaseQuestion: Codable {
    let id: UUID
    let storyId: UUID
    let userId: UUID
    let userName: String
    let text: String
    let isAudio: Bool
    let audioFileURL: String?
    let answerText: String?
    let answerAudioFileURL: String?
    let isAnswered: Bool
    let answeredAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storyId         = "story_id"
        case userId          = "user_id"
        case userName        = "user_name"
        case text
        case isAudio         = "is_audio"
        case audioFileURL    = "audio_file_url"
        case answerText      = "answer_text"
        case answerAudioFileURL = "answer_audio_file_url"
        case isAnswered      = "is_answered"
        case answeredAt      = "answered_at"
        case createdAt       = "created_at"
    }

    init(from question: StoryQuestion, userId: UUID) {
        self.id               = question.id
        self.storyId          = question.storyId
        self.userId           = userId
        self.userName         = question.userName
        self.text             = question.text
        self.isAudio          = question.isAudio
        self.audioFileURL     = question.audioFileName
        self.answerText       = question.answerText
        self.answerAudioFileURL = question.answerAudioFileName
        self.isAnswered       = question.isAnswered
        self.answeredAt       = question.answeredDate
        self.createdAt        = question.dateCreated
    }
}

// MARK: Reaction (Likes)

struct SupabaseReaction: Codable {
    let storyId: UUID
    let userId: UUID
    let type: String

    enum CodingKeys: String, CodingKey {
        case storyId = "story_id"
        case userId  = "user_id"
        case type
    }
}

// MARK: Increment Like RPC Params
// Explicit nonisolated encode so this value type can satisfy `Encodable & Sendable`
// even when the module defaults to MainActor isolation.

struct IncrementLikeParams: Sendable {
    let pStoryId: UUID
    let delta: Int
}

extension IncrementLikeParams: Encodable {
    enum CodingKeys: String, CodingKey {
        case pStoryId = "p_story_id"
        case delta
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pStoryId, forKey: .pStoryId)
        try container.encode(delta, forKey: .delta)
    }
}

// MARK: Profile Update Payloads

struct ProfileRoleUpdate: Encodable {
    let role: String
}

struct ProfileNameUpdate: Encodable {
    let name: String
    let birthYear: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case birthYear = "birth_year"
    }
}

struct ProfileTierUpdate: Encodable {
    let subscriptionTier: String

    enum CodingKeys: String, CodingKey {
        case subscriptionTier = "subscription_tier"
    }
}
