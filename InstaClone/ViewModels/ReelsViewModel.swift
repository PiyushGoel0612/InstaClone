//
//  ReelsViewModel.swift
//  InstaClone
//
//  Created by Piyush Goel on 22/12/25.
//

import Foundation
import AVKit
internal import Combine

// Model representing a single reel
struct Reel: Identifiable, Codable, Equatable {
    let id: String
    let userName: String
    let userImage: String
    let reelVideo: String
    var likeCount: Int
    var likedByUser: Bool

    // Maps API response keys to Swift property names
    enum CodingKeys: String, CodingKey {
        case id = "reel_id"
        case userName = "user_name"
        case userImage = "user_image"
        case reelVideo = "reel_video"
        case likeCount = "like_count"
        case likedByUser = "liked_by_user"
    }
}

// Wrapper for reels API response
struct ReelsResponse: Codable {
    let reels: [Reel]
}

// Request body for like / dislike reel API
struct ReelLikeRequest: Codable {
    let like: Bool
    let reelsId: String

    enum CodingKeys: String, CodingKey {
        case like
        case reelsId = "reels_id"
    }
}

// Manages AVPlayer lifecycle for reels playback
class VideoPlayerManager: ObservableObject {

    @Published var player: AVPlayer?        // AVPlayer instance
    @Published var isMuted = true            // Mute state shared across reels

    private var observer: NSObjectProtocol?  // Playback completion observer
    private var currentURL: String?          // Currently loaded video URL

    // Loads a video URL and starts playback
    func loadAndPlay(url: String) {

        // If same video is already loaded, just resume playback
        guard currentURL != url else {
            player?.play()
            return
        }

        // Clean previous player before loading new video
        stopAndClean()

        guard let videoURL = URL(string: url) else { return }
        currentURL = url

        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = isMuted

        // Loop video when playback ends
        observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }

        player?.play()
    }

    // Stops playback and releases player resources
    func stopAndClean() {

        // Remove playback observer
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }

        // Stop and release AVPlayer
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        currentURL = nil
    }

    // Toggles mute state for the player
    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }

    // Cleanup on deallocation
    deinit {
        stopAndClean()
    }
}

// Main ViewModel responsible for reels feed & interactions
class ReelsViewModel: ObservableObject {

    @Published var reels: [Reel] = []        // Reels feed data
    @Published var isLoading = false         // Loading indicator state
    @Published var errorMessage: String?     // Error message for UI
    @Published var showToast = false         // Toast visibility flag
    @Published var toastMessage: String?     // Toast message text

    private let baseURL = "https://dfbf9976-22e3-4bb2-ae02-286dfd0d7c42.mock.pstmn.io"
    private let coreDataManager = CoreDataManager.shared

    // Fetch reels from API with offline fallback
    func fetchReels() async {

        // Reset UI state before fetch
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let url = URL(string: "\(baseURL)/user/reels")!
            let (data, _) = try await URLSession.shared.data(from: url)

            let response = try JSONDecoder().decode(ReelsResponse.self, from: data)

            // Cache reels locally
            coreDataManager.saveReels(response.reels)

            // Update UI with fresh data
            await MainActor.run {
                reels = response.reels
            }

        } catch {
            // Load cached reels if network fails
            let cachedReels = coreDataManager.fetchReels()

            await MainActor.run {
                if !cachedReels.isEmpty {
                    reels = cachedReels
                    showToastMessage("No network. Showing cached data.")
                } else {
                    errorMessage = "Failed to load reels: \(error.localizedDescription)"
                }
            }
        }

        // Stop loading indicator
        await MainActor.run {
            isLoading = false
        }
    }

    // Toggles like / unlike for a reel with optimistic UI update
    func toggleLike(for reel: Reel) async {

        // Locate reel index
        guard let index = reels.firstIndex(where: { $0.id == reel.id }) else { return }

        // Save previous state for rollback
        let oldState = reels[index].likedByUser
        let oldCount = reels[index].likeCount

        // Optimistically update UI
        await MainActor.run {
            reels[index].likedByUser.toggle()
            reels[index].likeCount += reels[index].likedByUser ? 1 : -1
        }

        // Persist optimistic update locally
        var updatedReel = reel
        updatedReel.likedByUser = !oldState
        updatedReel.likeCount += updatedReel.likedByUser ? 1 : -1
        coreDataManager.updateReel(updatedReel)

        do {
            // Trigger appropriate API call
            if !oldState {
                try await likeReel(reelId: reel.id)
            } else {
                try await dislikeReel(reelId: reel.id)
            }

        } catch {
            // Rollback UI on failure
            await MainActor.run {
                reels[index].likedByUser = oldState
                reels[index].likeCount = oldCount
            }

            // Rollback persisted data
            var revertedReel = reel
            revertedReel.likedByUser = oldState
            revertedReel.likeCount = oldCount
            coreDataManager.updateReel(revertedReel)

            // Show error toast
            await MainActor.run {
                showToastMessage("Unable to update like. Please try again")
            }
        }
    }

    // Sends POST request to like a reel
    private func likeReel(reelId: String) async throws {

        let url = URL(string: "\(baseURL)/user/like")!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let likeRequest = ReelLikeRequest(like: true, reelsId: reelId)
        request.httpBody = try JSONEncoder().encode(likeRequest)

        let (_, response) = try await URLSession.shared.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }

    // Sends DELETE request to dislike a reel
    private func dislikeReel(reelId: String) async throws {

        let url = URL(string: "\(baseURL)/user/dislike")!
        var request = URLRequest(url: url)

        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let likeRequest = ReelLikeRequest(like: false, reelsId: reelId)
        request.httpBody = try JSONEncoder().encode(likeRequest)

        let (_, response) = try await URLSession.shared.data(for: request)

        // Validate HTTP response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }

    // Shows a temporary toast message to the user
    private func showToastMessage(_ message: String) {

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
