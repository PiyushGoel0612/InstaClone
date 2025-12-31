//
//  FeedViewModel.swift
//  InstaClone
//
//  Created by Piyush Goel on 22/12/25.
//

import Foundation
internal import Combine

// ============================================================================
// Feed View Models
// ============================================================================

// Struct defined to hold details of every post
// that is fetched from the FetchReels URL
struct Post: Identifiable, Codable {
    let id: String
    let userName: String
    let userImage: String
    let postImage: String
    var likeCount: Int
    var likedByUser: Bool
    
    // enum defined to convert the recieved data
    // comfortably into the struct form
    enum CodingKeys: String, CodingKey {
        case id = "post_id"
        case userName = "user_name"
        case userImage = "user_image"
        case postImage = "post_image"
        case likeCount = "like_count"
        case likedByUser = "liked_by_user"
    }
}

// Array of Posts that is recieved from the
// FetchReel URL is stored in this struct
struct FeedResponse: Codable {
    let feed: [Post]
}

// struct defined to manage the packet data
// sent to LikeRequest
struct LikeRequest: Codable {
    let like: Bool
    let postId: String
    
    enum CodingKeys: String, CodingKey {
        case like
        case postId = "post_id"
    }
}

enum NetworkError: Error {
    case invalidResponse
}

// Main class implemented to manage all the important functionalities
//  of the feed view of the App
class FeedViewModel: ObservableObject {
    @Published var isLoading: Bool = true           // True if the data is still fetching
    @Published var posts: [Post] = []               // Hold all the recieved feed data
    @Published var errorMessage: String?            // Is not nil only if there is an error message to show
    @Published var showToast: Bool = false          // True if there is a toast message to show
    @Published var toastMessage: String?            // Not nil incase of a toast message
    
    // Hardcoded FeedFetch URL
    private let baseURL = "https://dfbf9976-22e3-4bb2-ae02-286dfd0d7c42.mock.pstmn.io"
    private let coreDataManager = CoreDataManager.shared
    
    func fetchFeed() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let url = URL(string: "\(baseURL)/user/feed")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let feedResponse = try JSONDecoder().decode(FeedResponse.self, from: data)
            
            coreDataManager.savePosts(feedResponse.feed)
            
            await MainActor.run {
                posts = feedResponse.feed
            }
            
        } catch {
            let cachedPosts = coreDataManager.fetchPosts()
            
            await MainActor.run {
                if !cachedPosts.isEmpty {
                    posts = cachedPosts
                    showToastMessage("No network. Showing cached data.")
                } else {
                    errorMessage = "Failed to load feed: \(error.localizedDescription)"
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    // Toggles like / unlike for a given post
    // Implements optimistic UI update with rollback on failure
    func toggleLike(for post: Post) async {

        // Find index of the post in current feed
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }

        // Preserve old state in case we need to rollback
        let oldState = posts[index].likedByUser
        let oldCount = posts[index].likeCount

        // Toggle like state
        let newState = !oldState

        // Optimistically update UI on main thread
        await MainActor.run {
            posts[index].likedByUser = newState
            posts[index].likeCount += newState ? 1 : -1
        }

        // Optimistic update to Core Data
        var updatedPost = post
        updatedPost.likedByUser = newState
        updatedPost.likeCount += newState ? 1 : -1
        coreDataManager.updatePost(updatedPost)

        do {
            // Call appropriate API
            if newState {
                try await likePost(postId: post.id)
            } else {
                try await dislikePost(postId: post.id)
            }
        } catch {
            // Rollback UI state on failure
            await MainActor.run {
                posts[index].likedByUser = oldState
                posts[index].likeCount = oldCount
            }

            // Rollback Core Data state
            var revertedPost = post
            revertedPost.likedByUser = oldState
            revertedPost.likeCount = oldCount
            coreDataManager.updatePost(revertedPost)

            // Inform user about failure
            await MainActor.run {
                showToastMessage("Unable to update like. Please try again")
            }
        }
    }

    // Sends POST request to like a post
    private func likePost(postId: String) async throws {

        // Construct endpoint
        let url = URL(string: "\(baseURL)/user/like")!
        var request = URLRequest(url: url)

        // Configure request
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode request body
        let likeRequest = LikeRequest(like: true, postId: postId)
        request.httpBody = try JSONEncoder().encode(likeRequest)

        // Perform network call
        let (_, response) = try await URLSession.shared.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }

    // Sends DELETE request to remove like from a post
    private func dislikePost(postId: String) async throws {

        // Construct endpoint
        let url = URL(string: "\(baseURL)/user/dislike")!
        var request = URLRequest(url: url)

        // Configure request
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode request body
        let likeRequest = LikeRequest(like: false, postId: postId)
        request.httpBody = try JSONEncoder().encode(likeRequest)

        // Perform network call
        let (_, response) = try await URLSession.shared.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }

    // Displays a temporary toast message
    private func showToastMessage(_ message: String) {

        // Set toast content
        toastMessage = message
        showToast = true

        // Auto-dismiss toast after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showToast = false
                toastMessage = nil
            }
        }
    }
}
