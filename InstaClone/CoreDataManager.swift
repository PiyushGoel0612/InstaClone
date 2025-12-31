//
//  CoreDataManager.swift
//  InstaClone
//
//  Created by Piyush Goel on 23/12/25.
//

import Foundation
import CoreData

// ============================================================================
// CoreDataManager
// ---------------------------------------------------------------------------
// Centralized Core Data helper responsible for:
// - Saving & fetching Posts
// - Saving & fetching Reels
// - Updating likes
// - Clearing cached data
// ============================================================================

class CoreDataManager {

    // Shared singleton instance
    static let shared = CoreDataManager()

    // Reference to PersistenceController (Core Data stack)
    private let persistenceController = PersistenceController.shared

    // Main view context used for all Core Data operations
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }

    // Private initializer to enforce singleton usage
    private init() {}

    // =========================================================================
    // Posts Operations
    // =========================================================================

    // Save posts to Core Data (clears existing cache first)
    func savePosts(_ posts: [Post]) {
        context.perform {

            // Remove old cached posts
            self.clearAllPosts()

            // Insert new posts
            for post in posts {
                let postEntity = PostEntity(context: self.context)
                postEntity.id = post.id
                postEntity.userName = post.userName
                postEntity.userImage = post.userImage
                postEntity.postImage = post.postImage
                postEntity.likeCount = Int32(post.likeCount)
                postEntity.likedByUser = post.likedByUser
            }

            // Persist changes
            self.saveContext()
        }
    }

    // Fetch all cached posts from Core Data
    func fetchPosts() -> [Post] {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()

        // Sort posts deterministically
        request.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]

        do {
            let postEntities = try context.fetch(request)

            // Convert Core Data entities → domain models
            return postEntities.map { entity in
                Post(
                    id: entity.id ?? "",
                    userName: entity.userName ?? "",
                    userImage: entity.userImage ?? "",
                    postImage: entity.postImage ?? "",
                    likeCount: Int(entity.likeCount),
                    likedByUser: entity.likedByUser
                )
            }
        } catch {
            print("Error fetching posts: \(error)")
            return []
        }
    }

    // Update a single post (used mainly for like toggles)
    func updatePost(_ post: Post) {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", post.id)

        do {
            let results = try context.fetch(request)
            if let postEntity = results.first {
                postEntity.userName = post.userName
                postEntity.userImage = post.userImage
                postEntity.postImage = post.postImage
                postEntity.likeCount = Int32(post.likeCount)
                postEntity.likedByUser = post.likedByUser

                saveContext()
            }
        } catch {
            print("Error updating post: \(error)")
        }
    }

    // Remove all cached posts using batch delete
    func clearAllPosts() {
        let request: NSFetchRequest<NSFetchRequestResult> = PostEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("Error clearing posts: \(error)")
        }
    }

    // =========================================================================
    // Reels Operations
    // =========================================================================

    // Save reels to Core Data (clears existing cache first)
    func saveReels(_ reels: [Reel]) {
        context.perform {

            // Remove old cached reels
            self.clearAllReels()

            // Insert new reels
            for reel in reels {
                let reelEntity = ReelEntity(context: self.context)
                reelEntity.id = reel.id
                reelEntity.userName = reel.userName
                reelEntity.userImage = reel.userImage
                reelEntity.reelVideo = reel.reelVideo
                reelEntity.likeCount = Int32(reel.likeCount)
                reelEntity.likedByUser = reel.likedByUser
            }

            // Persist changes
            self.saveContext()
        }
    }

    // Fetch all cached reels from Core Data
    func fetchReels() -> [Reel] {
        let request: NSFetchRequest<ReelEntity> = ReelEntity.fetchRequest()

        // Sort reels deterministically
        request.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]

        do {
            let reelEntities = try context.fetch(request)

            // Convert Core Data entities → domain models
            return reelEntities.map { entity in
                Reel(
                    id: entity.id ?? "",
                    userName: entity.userName ?? "",
                    userImage: entity.userImage ?? "",
                    reelVideo: entity.reelVideo ?? "",
                    likeCount: Int(entity.likeCount),
                    likedByUser: entity.likedByUser
                )
            }
        } catch {
            print("Error fetching reels: \(error)")
            return []
        }
    }

    // Update a single reel (used mainly for like toggles)
    func updateReel(_ reel: Reel) {
        let request: NSFetchRequest<ReelEntity> = ReelEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", reel.id)

        do {
            let results = try context.fetch(request)
            if let reelEntity = results.first {
                reelEntity.userName = reel.userName
                reelEntity.userImage = reel.userImage
                reelEntity.reelVideo = reel.reelVideo
                reelEntity.likeCount = Int32(reel.likeCount)
                reelEntity.likedByUser = reel.likedByUser

                saveContext()
            }
        } catch {
            print("Error updating reel: \(error)")
        }
    }

    // Remove all cached reels using batch delete
    func clearAllReels() {
        let request: NSFetchRequest<NSFetchRequestResult> = ReelEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            saveContext()
        } catch {
            print("Error clearing reels: \(error)")
        }
    }

    // =========================================================================
    // Context Saving
    // =========================================================================

    // Persist Core Data context changes safely
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
