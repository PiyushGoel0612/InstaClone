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

struct Post: Identifiable, Codable {
    let id: String
    let userName: String
    let userImage: String
    let postImage: String
    var likeCount: Int
    var likedByUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "post_id"
        case userName = "user_name"
        case userImage = "user_image"
        case postImage = "post_image"
        case likeCount = "like_count"
        case likedByUser = "liked_by_user"
    }
}

struct FeedResponse: Codable {
    let feed: [Post]
}

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

class FeedViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var posts: [Post] = []
    @Published var errorMessage: String?
    @Published var showToast: Bool = false
    @Published var toastMessage: String?
    
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
    
    func toggleLike(for post: Post) async {
        guard let index = posts.firstIndex(where: {$0.id == post.id}) else { return }
        
        let oldState = posts[index].likedByUser
        let oldCount = posts[index].likeCount
        
        let newState = !oldState
        
        await MainActor.run {
            posts[index].likedByUser = newState
            posts[index].likeCount += newState ? 1 : -1
        }
        
        var updatedPost = post
        updatedPost.likedByUser = newState
        updatedPost.likeCount += newState ? 1 : -1
        coreDataManager.updatePost(updatedPost)
        
        do {
            if newState {
                try await likePost(postId: post.id)
            } else {
                try await dislikePost(postId: post.id)
            }
        } catch {
            await MainActor.run {
                posts[index].likedByUser = oldState
                posts[index].likeCount = oldCount
            }
            
            var revertedPost = post
            revertedPost.likedByUser = oldState
            revertedPost.likeCount = oldCount
            coreDataManager.updatePost(revertedPost)
            
            await MainActor.run {
                showToastMessage("Unable to update like. Please try again")
            }
        }
    }
    
    private func likePost(postId: String) async throws {
        let url = URL(string: "\(baseURL)/user/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let likeRequest = LikeRequest(like: true, postId: postId)
        request.httpBody = try JSONEncoder().encode(likeRequest)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    private func dislikePost(postId: String) async throws {
        let url = URL(string: "\(baseURL)/user/dislike")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let likeRequest = LikeRequest(like: false, postId: postId)
        request.httpBody = try JSONEncoder().encode(likeRequest)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showToast = false
                toastMessage = nil
            }
        }
    }
}
