import Foundation
import SwiftData
import Supabase

// MARK: - SyncManager
// Handles two-way sync between SwiftData (local cache) and Supabase (source of truth).
// Strategy: push-on-write + pull-on-launch.
// All methods are fire-and-forget (except pullAllUserData, which is also fire-and-forget
// but internally awaits the network calls before updating SwiftData on MainActor).

final class SyncManager {

    static let shared = SyncManager()

    private var modelContext: ModelContext?

    private init() {}

    // MARK: - Configure

    /// Called once from StoryloomApp.init() with the SwiftData main context.
    func configure(with context: ModelContext) {
        modelContext = context
    }

    // MARK: - Pull (Supabase → SwiftData)

    /// Fetches all folders and stories for the current user from Supabase
    /// and merges them into the local SwiftData store. Safe to call multiple times.
    func pullAllUserData() {
        guard let uid = AuthManager.shared.supabaseUserId,
              let context = modelContext else { return }

        Task {
            do {
                // Fetch folders and stories in parallel
                async let remoteFolders: [SupabaseFolder] = SupabaseManager.shared.client
                    .from("folders")
                    .select()
                    .eq("owner_id", value: uid.uuidString)
                    .execute()
                    .value

                async let remoteStories: [SupabaseStory] = SupabaseManager.shared.client
                    .from("stories")
                    .select()
                    .eq("owner_id", value: uid.uuidString)
                    .execute()
                    .value

                let (folders, stories) = try await (remoteFolders, remoteStories)

                // Collect story UUIDs so we can fetch related comments/questions
                let storyIds = stories.map { $0.id.uuidString }

                // Fetch comments and questions for user's stories
                var remoteComments: [SupabaseComment] = []
                var remoteQuestions: [SupabaseQuestion] = []

                if !storyIds.isEmpty {
                    // Fetch comments where story_id in user's stories
                    // Supabase PostgREST: use .in() filter
                    remoteComments = (try? await SupabaseManager.shared.client
                        .from("comments")
                        .select()
                        .in("story_id", values: storyIds)
                        .execute()
                        .value) ?? []

                    remoteQuestions = (try? await SupabaseManager.shared.client
                        .from("questions")
                        .select()
                        .in("story_id", values: storyIds)
                        .execute()
                        .value) ?? []
                }

                await MainActor.run {
                    self.applyRemoteFolders(folders, context: context)
                    self.applyRemoteStories(stories, context: context)
                    self.applyRemoteComments(remoteComments, context: context)
                    self.applyRemoteQuestions(remoteQuestions, context: context)
                }
            } catch {
                print("SyncManager: pullAllUserData failed — \(error.localizedDescription)")
            }
        }
    }

    /// Async variant of pullAllUserData — awaits completion so .refreshable can show the indicator.
    @MainActor
    func pullAllUserDataAsync() async {
        guard let uid = AuthManager.shared.supabaseUserId,
              let context = modelContext else { return }
        do {
            async let remoteFolders: [SupabaseFolder] = SupabaseManager.shared.client
                .from("folders")
                .select()
                .eq("owner_id", value: uid.uuidString)
                .execute()
                .value
            async let remoteStories: [SupabaseStory] = SupabaseManager.shared.client
                .from("stories")
                .select()
                .eq("owner_id", value: uid.uuidString)
                .execute()
                .value
            let (folders, stories) = try await (remoteFolders, remoteStories)
            let storyIds = stories.map { $0.id.uuidString }
            var remoteComments: [SupabaseComment] = []
            var remoteQuestions: [SupabaseQuestion] = []
            if !storyIds.isEmpty {
                remoteComments = (try? await SupabaseManager.shared.client
                    .from("comments").select()
                    .in("story_id", values: storyIds).execute().value) ?? []
                remoteQuestions = (try? await SupabaseManager.shared.client
                    .from("questions").select()
                    .in("story_id", values: storyIds).execute().value) ?? []
            }
            self.applyRemoteFolders(folders, context: context)
            self.applyRemoteStories(stories, context: context)
            self.applyRemoteComments(remoteComments, context: context)
            self.applyRemoteQuestions(remoteQuestions, context: context)
        } catch {
            print("SyncManager: pullAllUserDataAsync failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Push: Story

    /// Upserts a story to Supabase and uploads any media files to Storage.
    func pushStory(_ story: StoryEntry) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        let payload = SupabaseStory(from: story, ownerId: uid)
        let storyUUID = story.uuid
        let narrationFileName = story.narrationFileName
        let imageFileName = story.imageFileName
        let hasNarration = story.hasNarration

        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("stories")
                    .upsert(payload)
                    .execute()

                // Upload audio to Storage if present
                if hasNarration, let audioFile = narrationFileName {
                    await uploadAudio(storyUUID: storyUUID, localFileName: audioFile)
                }

                // Upload image to Storage if present
                if let imgFile = imageFileName {
                    await uploadImage(storyUUID: storyUUID, localFileName: imgFile)
                }
            } catch {
                print("SyncManager: pushStory failed — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Storage: Upload

    private func uploadAudio(storyUUID: UUID, localFileName: String) async {
        let url = AudioManager.narrationURL(fileName: localFileName)
        guard let data = try? Data(contentsOf: url) else {
            print("SyncManager: uploadAudio — local file not found: \(localFileName)")
            return
        }
        let storagePath = "\(storyUUID.uuidString).m4a"
        do {
            try await SupabaseManager.shared.client.storage
                .from("story-audio")
                .upload(storagePath, data: data, options: FileOptions(contentType: "audio/mp4", upsert: true))
            print("SyncManager: uploaded audio to story-audio/\(storagePath)")
        } catch {
            print("SyncManager: uploadAudio failed — \(error.localizedDescription)")
        }
    }

    private func uploadImage(storyUUID: UUID, localFileName: String) async {
        let url = ImageManager.imageURL(fileName: localFileName)
        guard let data = try? Data(contentsOf: url) else {
            print("SyncManager: uploadImage — local file not found: \(localFileName)")
            return
        }
        let storagePath = "\(storyUUID.uuidString).jpg"
        do {
            try await SupabaseManager.shared.client.storage
                .from("story-images")
                .upload(storagePath, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            print("SyncManager: uploaded image to story-images/\(storagePath)")
        } catch {
            print("SyncManager: uploadImage failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Storage: Download

    /// Downloads audio and image files for a story that arrived from a remote sync.
    /// Only downloads if the file doesn't already exist locally.
    func downloadMediaIfNeeded(storyUUID: UUID, hasNarration: Bool, publishNarration: Bool, hasImage: Bool) {
        Task {
            if hasNarration && publishNarration {
                let localName = storyUUID.uuidString + ".m4a"
                if !AudioManager.narrationExists(fileName: localName) {
                    await downloadAudio(storyUUID: storyUUID, saveAs: localName)
                }
            }
            if hasImage {
                let localName = storyUUID.uuidString + ".jpg"
                if !ImageManager.imageExists(fileName: localName) {
                    await downloadImage(storyUUID: storyUUID, saveAs: localName)
                }
            }
        }
    }

    private func downloadAudio(storyUUID: UUID, saveAs localName: String) async {
        let storagePath = "\(storyUUID.uuidString).m4a"
        do {
            let data = try await SupabaseManager.shared.client.storage
                .from("story-audio")
                .download(path: storagePath)
            let destURL = AudioManager.narrationURL(fileName: localName)
            try data.write(to: destURL)
            print("SyncManager: downloaded audio to \(localName)")
            // Update narrationFileName on the matching local StoryEntry
            await MainActor.run {
                guard let context = self.modelContext else { return }
                let stories = (try? context.fetch(FetchDescriptor<StoryEntry>())) ?? []
                if let entry = stories.first(where: { $0.uuid == storyUUID }) {
                    entry.narrationFileName = localName
                }
            }
        } catch {
            print("SyncManager: downloadAudio failed — \(error.localizedDescription)")
        }
    }

    private func downloadImage(storyUUID: UUID, saveAs localName: String) async {
        let storagePath = "\(storyUUID.uuidString).jpg"
        do {
            let data = try await SupabaseManager.shared.client.storage
                .from("story-images")
                .download(path: storagePath)
            let destURL = ImageManager.imageURL(fileName: localName)
            try data.write(to: destURL)
            print("SyncManager: downloaded image to \(localName)")
            // Update imageFileName on the matching local StoryEntry
            await MainActor.run {
                guard let context = self.modelContext else { return }
                let stories = (try? context.fetch(FetchDescriptor<StoryEntry>())) ?? []
                if let entry = stories.first(where: { $0.uuid == storyUUID }) {
                    entry.imageFileName = localName
                }
            }
        } catch {
            print("SyncManager: downloadImage failed — \(error.localizedDescription)")
        }
    }

    /// Deletes a story from Supabase by its UUID.
    func deleteStory(uuid: UUID) {
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("stories")
                    .delete()
                    .eq("id", value: uuid.uuidString)
                    .execute()
            } catch {
                print("SyncManager: deleteStory failed — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Push: Folder

    /// Upserts a folder to Supabase. Uses folder.id as the Supabase row id.
    func pushFolder(_ folder: Folder) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        let payload = SupabaseFolder(id: folder.id, ownerId: uid, name: folder.name, dateCreated: folder.dateCreated)
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("folders")
                    .upsert(payload)
                    .execute()
            } catch {
                print("SyncManager: pushFolder failed — \(error.localizedDescription)")
            }
        }
    }

    /// Deletes a folder from Supabase by its UUID.
    /// Stories in the folder will have their folder_id set to NULL by the ON DELETE SET NULL constraint.
    func deleteFolder(id: UUID) {
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("folders")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .execute()
            } catch {
                print("SyncManager: deleteFolder failed — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Push: Comment

    func pushComment(_ comment: StoryComment) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        let payload = SupabaseComment(from: comment, userId: uid)
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("comments")
                    .upsert(payload)
                    .execute()
            } catch {
                print("SyncManager: pushComment failed — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Push: Question

    func pushQuestion(_ question: StoryQuestion) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        let payload = SupabaseQuestion(from: question, userId: uid)
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("questions")
                    .upsert(payload)
                    .execute()
            } catch {
                print("SyncManager: pushQuestion failed — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Push: Likes / Reactions

    /// Records a like (heart reaction) for a story and increments the like_count.
    func pushLike(storyUUID: UUID) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        let reaction = SupabaseReaction(storyId: storyUUID, userId: uid, type: "heart")
        Task {
            do {
                // Upsert reaction (idempotent — user can only like once)
                try await SupabaseManager.shared.client
                    .from("reactions")
                    .upsert(reaction)
                    .execute()

                // Increment like_count via RPC
                try await SupabaseManager.shared.client
                    .rpc("increment_like_count", params: IncrementLikeParams(pStoryId: storyUUID, delta: 1))
                    .execute()
            } catch {
                print("SyncManager: pushLike failed — \(error.localizedDescription)")
            }
        }
    }

    /// Removes a like and decrements the like_count.
    func removeLike(storyUUID: UUID) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        Task {
            do {
                // Delete reaction
                try await SupabaseManager.shared.client
                    .from("reactions")
                    .delete()
                    .eq("story_id", value: storyUUID.uuidString)
                    .eq("user_id", value: uid.uuidString)
                    .execute()

                // Decrement like_count via RPC
                try await SupabaseManager.shared.client
                    .rpc("increment_like_count", params: IncrementLikeParams(pStoryId: storyUUID, delta: -1))
                    .execute()
            } catch {
                print("SyncManager: removeLike failed — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Apply Remote Data to SwiftData

    @MainActor
    private func applyRemoteComments(_ remoteComments: [SupabaseComment], context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<StoryComment>())) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for rc in remoteComments {
            if let local = existingById[rc.id] {
                local.text = rc.text
            } else {
                let comment = StoryComment(
                    storyId: rc.storyId,
                    userName: rc.userName,
                    text: rc.text,
                    parentCommentId: rc.parentCommentId,
                    replyToUserName: rc.replyToUserName
                )
                comment.id = rc.id
                comment.userId = rc.userId
                if let createdAt = rc.createdAt { comment.dateCreated = createdAt }
                context.insert(comment)
            }
        }
    }

    @MainActor
    private func applyRemoteQuestions(_ remoteQuestions: [SupabaseQuestion], context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<StoryQuestion>())) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for rq in remoteQuestions {
            if let local = existingById[rq.id] {
                local.text = rq.text
                local.answerText = rq.answerText
                local.isAnswered = rq.isAnswered
                local.answeredDate = rq.answeredAt
            } else {
                let question = StoryQuestion(
                    storyId: rq.storyId,
                    userName: rq.userName,
                    text: rq.text,
                    isAudio: rq.isAudio,
                    audioFileName: rq.audioFileURL
                )
                question.id = rq.id
                question.userId = rq.userId
                question.answerText = rq.answerText
                question.isAnswered = rq.isAnswered
                question.answeredDate = rq.answeredAt
                if let createdAt = rq.createdAt { question.dateCreated = createdAt }
                context.insert(question)
            }
        }
    }

    @MainActor
    private func applyRemoteFolders(_ remoteFolders: [SupabaseFolder], context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Folder>())) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for rf in remoteFolders {
            if let local = existingById[rf.id] {
                // Update existing folder name
                local.name = rf.name
            } else {
                // Create new local folder from Supabase data
                let folder = Folder(name: rf.name)
                folder.id = rf.id
                folder.dateCreated = rf.dateCreated
                context.insert(folder)
            }
        }
    }

    @MainActor
    private func applyRemoteStories(_ remoteStories: [SupabaseStory], context: ModelContext) {
        // Build a lookup for all local folders by id (needed to assign folder relationships)
        let allFolders = (try? context.fetch(FetchDescriptor<Folder>())) ?? []
        let folderById = Dictionary(uniqueKeysWithValues: allFolders.map { ($0.id, $0) })

        // Build a lookup for all local stories by uuid
        let allStories = (try? context.fetch(FetchDescriptor<StoryEntry>())) ?? []
        let storyByUUID = Dictionary(uniqueKeysWithValues: allStories.map { ($0.uuid, $0) })

        for rs in remoteStories {
            // Resolve folder
            let folder: Folder? = rs.folderId.flatMap { folderById[$0] }

            if let local = storyByUUID[rs.id] {
                // Update existing local story with Supabase values
                local.title                  = rs.title
                local.content                = rs.content
                local.category               = rs.category
                local.promptQuestion         = rs.promptQuestion ?? ""
                local.isInVault              = rs.isPublished
                local.year                   = rs.year
                local.hasNarration           = rs.hasNarration
                local.publishNarration       = rs.publishNarration
                local.authorName             = rs.authorName
                local.likeCount              = rs.likeCount
                local.dateCreated            = rs.createdAt
                local.folder                 = folder
                if rs.ownerId == AuthManager.shared.supabaseUserId {
                    // Always use current user's live subscription tier for their own stories.
                    local.authorSubscriptionTier = AuthManager.shared.currentUser?.subscriptionTier ?? .premium
                } else if let tierStr = rs.authorSubscriptionTier {
                    local.authorSubscriptionTier = SubscriptionTier(rawValue: tierStr) ?? .premium
                }
                // Download media for reader devices (storyteller already has files locally)
                if rs.ownerId != AuthManager.shared.supabaseUserId {
                    downloadMediaIfNeeded(
                        storyUUID: rs.id,
                        hasNarration: rs.hasNarration,
                        publishNarration: rs.publishNarration,
                        hasImage: rs.imageFileName != nil
                    )
                }
            } else {
                // Create new local story from Supabase data
                let entry = StoryEntry(
                    title: rs.title,
                    content: rs.content,
                    category: rs.category,
                    promptQuestion: rs.promptQuestion ?? "",
                    isInVault: rs.isPublished,
                    year: rs.year,
                    folder: folder,
                    hasNarration: rs.hasNarration,
                    publishNarration: rs.publishNarration,
                    narrationFileName: rs.narrationFileName,
                    imageFileName: rs.imageFileName,
                    authorSubscriptionTier: {
                        if rs.ownerId == AuthManager.shared.supabaseUserId {
                            return AuthManager.shared.currentUser?.subscriptionTier ?? .premium
                        }
                        if let t = rs.authorSubscriptionTier { return SubscriptionTier(rawValue: t) ?? .premium }
                        return .premium
                    }(),
                    authorName: rs.authorName,
                    likeCount: rs.likeCount
                )
                entry.uuid        = rs.id
                entry.dateCreated = rs.createdAt
                context.insert(entry)
                // Download media for reader devices
                if rs.ownerId != AuthManager.shared.supabaseUserId {
                    downloadMediaIfNeeded(
                        storyUUID: rs.id,
                        hasNarration: rs.hasNarration,
                        publishNarration: rs.publishNarration,
                        hasImage: rs.imageFileName != nil
                    )
                }
            }
        }
    }
}
