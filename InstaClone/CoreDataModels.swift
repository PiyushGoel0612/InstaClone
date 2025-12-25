//
//  CoreDataModels.swift
//  InstaClone
//
//  Created by Piyush Goel on 23/12/25.
//

//  Core Data Entity Extensions

import Foundation
import CoreData

extension PostEntity {
    func toPost() -> Post {
        Post(
            id: id ?? "",
            userName: userName ?? "",
            userImage: userImage ?? "",
            postImage: postImage ?? "",
            likeCount: Int(likeCount),
            likedByUser: likedByUser
        )
    }
    
    func update(from post: Post) {
        self.id = post.id
        self.userName = post.userName
        self.userImage = post.userImage
        self.postImage = post.postImage
        self.likeCount = Int32(post.likeCount)
        self.likedByUser = post.likedByUser
    }
}

extension ReelEntity {
    func toReel() -> Reel {
        Reel(
            id: id ?? "",
            userName: userName ?? "",
            userImage: userImage ?? "",
            reelVideo: reelVideo ?? "",
            likeCount: Int(likeCount),
            likedByUser: likedByUser
        )
    }
    
    func update(from reel: Reel) {
        self.id = reel.id
        self.userName = reel.userName
        self.userImage = reel.userImage
        self.reelVideo = reel.reelVideo
        self.likeCount = Int32(reel.likeCount)
        self.likedByUser = reel.likedByUser
    }
}
