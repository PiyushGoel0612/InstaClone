//
//  InstaCloneTests.swift
//  InstaCloneTests
//
//  Created by Piyush Goel on 11/12/25.
//

import Testing
@testable import InstaClone
import Foundation

//struct InstaCloneTests {
//
//    @Test func example() async throws {
//        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
//    }
//
//}

@Suite("Basic Login Tests")
struct BasicLoginTests {
    
    @Test("User can login with correct credentials")
    func loginWithCorrectCredentials() {

        let viewModel = LoginViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        viewModel.login()
        
        #expect(viewModel.isLoggedIn == true)
    }
    
    @Test("User cannot login with wrong password")
    func loginWithWrongPassword() {
        let viewModel = LoginViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "wrongpassword"
        
        viewModel.login()
        
        #expect(viewModel.isLoggedIn == false)
        #expect(viewModel.errorMessage == "Invalid Credentials")
    }
    
    @Test("Empty email and password is invalid")
    func emptyFieldsAreInvalid() {
        let viewModel = LoginViewModel()
        viewModel.email = ""
        viewModel.password = ""
        
        #expect(viewModel.isValidForm == false)
    }
    
    @Test("Logout clears the user data")
    func logoutClearsData() {
        let viewModel = LoginViewModel()
        
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        viewModel.login()
        
        viewModel.logout()
        
        #expect(viewModel.email == "")
        #expect(viewModel.password == "")
        #expect(viewModel.isLoggedIn == false)
    }
}

@Suite("Basic Core Data Tests")
struct BasicCoreDataTests {
    
    @Test("Can save and fetch posts")
    func saveAndFetchPosts() {
        let manager = CoreDataManager.shared
        
        let post = Post(
            id: "test_001",
            userName: "Test User",
            userImage: "https://example.com/user.jpg",
            postImage: "https://example.com/post.jpg",
            likeCount: 10,
            likedByUser: false
        )
        
        manager.savePosts([post])
        
        let fetchedPosts = manager.fetchPosts()
        let post0 = fetchedPosts[0]
        
        #expect(fetchedPosts.count == 1)
        #expect(post0.id == "test_001")
        #expect(post0.likeCount == 10)
        
        manager.clearAllPosts()
    }
    
    @Test("Can update a post's like count")
    func updatePostLikeCount() {
        let manager = CoreDataManager.shared
        
        manager.clearAllPosts()
        
        let post = Post(
            id: "test_001",
            userName: "Test User",
            userImage: "url",
            postImage: "url",
            likeCount: 10,
            likedByUser: false
        )
        manager.savePosts([post])
        
        var updatedPost = post
        updatedPost.likeCount = 20
        updatedPost.likedByUser = true
        manager.updatePost(updatedPost)
        
        let fetchedPosts = manager.fetchPosts()
        let post0 = fetchedPosts[0]
        
        #expect(post0.likeCount == 20)
        #expect(post0.likedByUser == true)
        
        manager.clearAllPosts()
    }
    
    @Test("Clearing posts removes all data")
    func clearingPostsRemovesAll() {
        let manager = CoreDataManager.shared
        
        manager.clearAllPosts()
        
        let posts = [
            Post(id: "1", userName: "User 1", userImage: "url", postImage: "url", likeCount: 10, likedByUser: false),
            Post(id: "2", userName: "User 2", userImage: "url", postImage: "url", likeCount: 20, likedByUser: false)
        ]
        manager.savePosts(posts)
        
        manager.clearAllPosts()
        
        let fetchedPosts = manager.fetchPosts()
        #expect(fetchedPosts.isEmpty)
    }
}


@Suite("Basic Post Model Tests")
struct BasicPostModelTests {
    
    @Test("Post decodes from JSON correctly")
    func postDecodesFromJSON() throws {
        let json = """
        {
            "post_id": "post_001",
            "user_name": "John Doe",
            "user_image": "https://example.com/user.jpg",
            "post_image": "https://example.com/post.jpg",
            "like_count": 42,
            "liked_by_user": true
        }
        """
        
        let data = json.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let post = try decoder.decode(Post.self, from: data)
        
        #expect(post.id == "post_001")
        #expect(post.userName == "John Doe")
        #expect(post.likeCount == 42)
        #expect(post.likedByUser == true)
    }
    
    @Test("Post encodes to JSON correctly")
    func postEncodesToJSON() throws {
        // Create a post
        let post = Post(
            id: "post_001",
            userName: "John Doe",
            userImage: "https://example.com/user.jpg",
            postImage: "https://example.com/post.jpg",
            likeCount: 42,
            likedByUser: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(post)
        
        let decoder = JSONDecoder()
        let decodedPost = try decoder.decode(Post.self, from: data)
        
        #expect(decodedPost.id == post.id)
        #expect(decodedPost.likeCount == post.likeCount)
    }
}

@Suite("Basic Reel Model Tests")
struct BasicReelModelTests {
    
    @Test("Reel decodes from JSON correctly")
    func reelDecodesFromJSON() throws {
        let json = """
        {
            "reel_id": "reel_001",
            "user_name": "Jane Doe",
            "user_image": "https://example.com/user.jpg",
            "reel_video": "https://example.com/reel.mp4",
            "like_count": 100,
            "liked_by_user": false
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let reel = try decoder.decode(Reel.self, from: data)
        
        #expect(reel.id == "reel_001")
        #expect(reel.userName == "Jane Doe")
        #expect(reel.likeCount == 100)
        #expect(reel.likedByUser == false)
    }
    
    @Test("Two reels with same ID are equal")
    func reelsWithSameIDareEqual() {
        let reel1 = Reel(
            id: "reel_001",
            userName: "User",
            userImage: "url",
            reelVideo: "url",
            likeCount: 50,
            likedByUser: false
        )
        
        let reel2 = Reel(
            id: "reel_001",
            userName: "User",
            userImage: "url",
            reelVideo: "url",
            likeCount: 50,
            likedByUser: false
        )
        
        #expect(reel1 == reel2)
    }
}
