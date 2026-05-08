import Foundation
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "erikfischer.Storyloom", category: "Sync")

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

    // MARK: - Clear Local Data (called on logout)

    /// Deletes all SwiftData records so a subsequent user on the same device
    /// cannot see the previous user's stories before a fresh sync overwrites them.
    @MainActor
    func clearLocalData() {
        guard let context = modelContext else { return }
        RealtimeManager.shared.stopListening()
        do {
            try context.delete(model: StoryReaction.self)
            try context.delete(model: StoryAccess.self)
            try context.delete(model: StoryInvite.self)
            try context.delete(model: StoryComment.self)
            try context.delete(model: StoryQuestion.self)
            try context.delete(model: StoryEntry.self)
            try context.delete(model: Folder.self)
            logger.debug("local data cleared on logout")
        } catch {
            logger.error("clearLocalData failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    // MARK: - Pull (Supabase → SwiftData)

    /// Fetches all folders and stories for the current user from Supabase
    /// and merges them into the local SwiftData store. Safe to call multiple times.
    func pullAllUserData() {
        guard let uid = AuthManager.shared.supabaseUserId,
              let context = modelContext else { return }

        let isReader = AuthManager.shared.currentUser?.role == .reader

        Task {
            do {
                if isReader {
                    // Readers: no owner_id filter — RLS returns only stories granted
                    // via story_access (i.e. stories in their vault).
                    let remoteStories: [SupabaseStory] = try await SupabaseManager.shared.client
                        .from("stories")
                        .select()
                        .execute()
                        .value

                    let storyIds = remoteStories.map { $0.id.uuidString }
                    var remoteComments: [SupabaseComment] = []
                    var remoteQuestions: [SupabaseQuestion] = []

                    if !storyIds.isEmpty {
                        remoteComments = (try? await SupabaseManager.shared.client
                            .from("comments").select()
                            .in("story_id", values: storyIds)
                            .execute().value) ?? []

                        remoteQuestions = (try? await SupabaseManager.shared.client
                            .from("questions").select()
                            .in("story_id", values: storyIds)
                            .execute().value) ?? []
                    }

                    await MainActor.run {
                        self.applyRemoteStories(remoteStories, context: context, forceVault: true)
                        self.applyRemoteComments(remoteComments, context: context)
                        self.applyRemoteQuestions(remoteQuestions, context: context)
                        RealtimeManager.shared.startListening(storyIds: remoteStories.map { $0.id })
                    }
                } else {
                    // Storytellers: fetch own folders and stories.
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
                            .in("story_id", values: storyIds)
                            .execute().value) ?? []

                        remoteQuestions = (try? await SupabaseManager.shared.client
                            .from("questions").select()
                            .in("story_id", values: storyIds)
                            .execute().value) ?? []
                    }

                    await MainActor.run {
                        self.applyRemoteFolders(folders, context: context)
                        self.applyRemoteStories(stories, context: context)
                        self.applyRemoteComments(remoteComments, context: context)
                        self.applyRemoteQuestions(remoteQuestions, context: context)
                        RealtimeManager.shared.startListening(storyIds: stories.map { $0.id })
                    }
                }
            } catch {
                logger.error("pullAllUserData failed: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    /// Async variant of pullAllUserData — awaits completion so .refreshable can show the indicator.
    @MainActor
    func pullAllUserDataAsync() async {
        guard let uid = AuthManager.shared.supabaseUserId,
              let context = modelContext else { return }

        let isReader = AuthManager.shared.currentUser?.role == .reader

        do {
            if isReader {
                let remoteStories: [SupabaseStory] = try await SupabaseManager.shared.client
                    .from("stories").select()
                    .execute().value

                let storyIds = remoteStories.map { $0.id.uuidString }
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

                self.applyRemoteStories(remoteStories, context: context, forceVault: true)
                self.applyRemoteComments(remoteComments, context: context)
                self.applyRemoteQuestions(remoteQuestions, context: context)
                RealtimeManager.shared.startListening(storyIds: remoteStories.map { $0.id })
            } else {
                async let remoteFolders: [SupabaseFolder] = SupabaseManager.shared.client
                    .from("folders").select()
                    .eq("owner_id", value: uid.uuidString)
                    .execute().value
                async let remoteStories: [SupabaseStory] = SupabaseManager.shared.client
                    .from("stories").select()
                    .eq("owner_id", value: uid.uuidString)
                    .execute().value

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
                RealtimeManager.shared.startListening(storyIds: stories.map { $0.id })
            }
        } catch {
            logger.error("pullAllUserDataAsync failed: \(error.localizedDescription, privacy: .private)")
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
                logger.error("pushStory failed: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    // MARK: - Storage: Upload

    private func uploadAudio(storyUUID: UUID, localFileName: String) async {
        let url = AudioManager.narrationURL(fileName: localFileName)
        guard let data = try? Data(contentsOf: url) else {
            logger.error("uploadAudio — local file not found")
            return
        }
        let storagePath = "\(storyUUID.uuidString).m4a"
        do {
            try await SupabaseManager.shared.client.storage
                .from("story-audio")
                .upload(storagePath, data: data, options: FileOptions(contentType: "audio/mp4", upsert: true))
            logger.debug("uploaded audio successfully")
        } catch {
            logger.error("uploadAudio failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    private func uploadImage(storyUUID: UUID, localFileName: String) async {
        let url = ImageManager.imageURL(fileName: localFileName)
        guard let data = try? Data(contentsOf: url) else {
            logger.error("uploadImage — local file not found")
            return
        }
        let storagePath = "\(storyUUID.uuidString).jpg"
        do {
            try await SupabaseManager.shared.client.storage
                .from("story-images")
                .upload(storagePath, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            logger.debug("uploaded image successfully")
        } catch {
            logger.error("uploadImage failed: \(error.localizedDescription, privacy: .private)")
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
            logger.debug("downloaded audio successfully")
            // Update narrationFileName on just the matching StoryEntry row.
            await MainActor.run {
                guard let context = self.modelContext else { return }
                let uuid = storyUUID
                var descriptor = FetchDescriptor<StoryEntry>(
                    predicate: #Predicate { $0.uuid == uuid }
                )
                descriptor.fetchLimit = 1
                if let entry = try? context.fetch(descriptor).first {
                    entry.narrationFileName = localName
                }
            }
        } catch {
            logger.error("downloadAudio failed: \(error.localizedDescription, privacy: .private)")
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
            logger.debug("downloaded image successfully")
            // Update imageFileName on just the matching StoryEntry row.
            await MainActor.run {
                guard let context = self.modelContext else { return }
                let uuid = storyUUID
                var descriptor = FetchDescriptor<StoryEntry>(
                    predicate: #Predicate { $0.uuid == uuid }
                )
                descriptor.fetchLimit = 1
                if let entry = try? context.fetch(descriptor).first {
                    entry.imageFileName = localName
                }
            }
        } catch {
            logger.error("downloadImage failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    /// Deletes a story from Supabase by its UUID.
    /// The owner_id filter is belt-and-suspenders — RLS enforces this server-side too.
    func deleteStory(uuid: UUID) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("stories")
                    .delete()
                    .eq("id", value: uuid.uuidString)
                    .eq("owner_id", value: uid.uuidString)
                    .execute()
            } catch {
                logger.error("deleteStory failed: \(error.localizedDescription, privacy: .private)")
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
                logger.error("pushFolder failed: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    /// Deletes a folder from Supabase by its UUID.
    /// Stories in the folder will have their folder_id set to NULL by the ON DELETE SET NULL constraint.
    /// The owner_id filter is belt-and-suspenders — RLS enforces this server-side too.
    func deleteFolder(id: UUID) {
        guard let uid = AuthManager.shared.supabaseUserId else { return }
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("folders")
                    .delete()
                    .eq("id", value: id.uuidString)
                    .eq("owner_id", value: uid.uuidString)
                    .execute()
            } catch {
                logger.error("deleteFolder failed: \(error.localizedDescription, privacy: .private)")
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
                logger.error("pushComment failed: \(error.localizedDescription, privacy: .private)")
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
                logger.error("pushQuestion failed: \(error.localizedDescription, privacy: .private)")
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
                logger.error("pushLike failed: \(error.localizedDescription, privacy: .private)")
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
                logger.error("removeLike failed: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    // MARK: - Realtime Single-Record Ingest

    /// Called by RealtimeManager when a single INSERT event arrives.
    /// Decodes the AnyJSON record directly into SwiftData — no network round-trip needed.
    /// Falls back to a full pull only if decoding fails (e.g. schema mismatch).
    @MainActor
    func ingestRealtimeRecord(table: String, record: [String: AnyJSON]) {
        guard let context = modelContext else { return }
        do {
            // AnyJSON is Encodable; round-trip through JSON to use the existing Codable models.
            let data = try JSONEncoder().encode(record)
            switch table {
            case "comments":
                let comment = try JSONDecoder().decode(SupabaseComment.self, from: data)
                upsertComment(comment, context: context)
            case "questions":
                let question = try JSONDecoder().decode(SupabaseQuestion.self, from: data)
                upsertQuestion(question, context: context)
            default:
                break
            }
        } catch {
            logger.error("ingestRealtimeRecord failed, falling back to full pull: \(error.localizedDescription, privacy: .private)")
            pullAllUserData()
        }
    }

    @MainActor
    private func upsertComment(_ rc: SupabaseComment, context: ModelContext) {
        let id = rc.id
        var descriptor = FetchDescriptor<StoryComment>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let local = (try? context.fetch(descriptor))?.first {
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

    @MainActor
    private func upsertQuestion(_ rq: SupabaseQuestion, context: ModelContext) {
        let id = rq.id
        var descriptor = FetchDescriptor<StoryQuestion>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let local = (try? context.fetch(descriptor))?.first {
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

    // MARK: - Apply Remote Data to SwiftData

    @MainActor
    private func applyRemoteComments(_ remoteComments: [SupabaseComment], context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<StoryComment>())) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let remoteIds = Set(remoteComments.map { $0.id })

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
        // Remove local records that no longer exist on the server.
        for local in existing where !remoteIds.contains(local.id) {
            context.delete(local)
        }
    }

    @MainActor
    private func applyRemoteQuestions(_ remoteQuestions: [SupabaseQuestion], context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<StoryQuestion>())) ?? []
        let existingById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let remoteIds = Set(remoteQuestions.map { $0.id })

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
        // Remove local records that no longer exist on the server.
        for local in existing where !remoteIds.contains(local.id) {
            context.delete(local)
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
    private func applyRemoteStories(_ remoteStories: [SupabaseStory], context: ModelContext, forceVault: Bool = false) {
        // Build a lookup for all local folders by id (needed to assign folder relationships)
        let allFolders = (try? context.fetch(FetchDescriptor<Folder>())) ?? []
        let folderById = Dictionary(uniqueKeysWithValues: allFolders.map { ($0.id, $0) })

        // Build a lookup for all local stories by uuid
        let allStories = (try? context.fetch(FetchDescriptor<StoryEntry>())) ?? []
        let storyByUUID = Dictionary(uniqueKeysWithValues: allStories.map { ($0.uuid, $0) })

        for rs in remoteStories {
            // Resolve folder
            let folder: Folder? = rs.folderId.flatMap { folderById[$0] }
            // forceVault=true when called for reader stories — they're always vault stories.
            let inVault = forceVault ? true : rs.isPublished

            if let local = storyByUUID[rs.id] {
                // Update existing local story with Supabase values
                local.title                  = rs.title
                local.content                = rs.content
                local.category               = rs.category
                local.promptQuestion         = rs.promptQuestion ?? ""
                local.isInVault              = inVault
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
                    isInVault: inVault,
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
