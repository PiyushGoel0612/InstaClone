//
//  CoreDataManager.swift
//  InstaClone
//
//  Created by Piyush Goel on 23/12/25.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistenceController = PersistenceController.shared
    
    private var context: NSManagedObjectContext {
        persistenceController.container.viewContext
    }
    
    private init() {}
    
    func savePosts(_ posts: [Post]) {
        context.perform {
            // Clear existing posts
            self.clearAllPosts()
            
            // Save new posts
            for post in posts {
                let postEntity = PostEntity(context: self.context)
                postEntity.id = post.id
                postEntity.userName = post.userName
                postEntity.userImage = post.userImage
                postEntity.postImage = post.postImage
                postEntity.likeCount = Int32(post.likeCount)
                postEntity.likedByUser = post.likedByUser
            }
            
            self.saveContext()
        }
    }
    
    func fetchPosts() -> [Post] {
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        do {
            let postEntities = try context.fetch(request)
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
    
    func saveReels(_ reels: [Reel]) {
        context.perform {
            // Clear existing reels
            self.clearAllReels()
            
            // Save new reels
            for reel in reels {
                let reelEntity = ReelEntity(context: self.context)
                reelEntity.id = reel.id
                reelEntity.userName = reel.userName
                reelEntity.userImage = reel.userImage
                reelEntity.reelVideo = reel.reelVideo
                reelEntity.likeCount = Int32(reel.likeCount)
                reelEntity.likedByUser = reel.likedByUser
            }
            
            self.saveContext()
        }
    }
    
    func fetchReels() -> [Reel] {
        let request: NSFetchRequest<ReelEntity> = ReelEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        do {
            let reelEntities = try context.fetch(request)
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
