//
//  ReelsViewModel.swift
//  InstaClone
//
//  Created by Piyush Goel on 22/12/25.
//

import Foundation
import AVKit
internal import Combine

struct Reel: Identifiable, Codable, Equatable {
    let id: String
    let userName: String
    let userImage: String
    let reelVideo: String
    var likeCount: Int
    var likedByUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "reel_id"
        case userName = "user_name"
        case userImage = "user_image"
        case reelVideo = "reel_video"
        case likeCount = "like_count"
        case likedByUser = "liked_by_user"
    }
}

struct ReelsResponse: Codable {
    let reels: [Reel]
}

struct ReelLikeRequest: Codable {
    let like: Bool
    let reelsId: String
    
    enum CodingKeys: String, CodingKey {
        case like
        case reelsId = "reels_id"
    }
}

class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isMuted = true
    private var observer: NSObjectProtocol?
    private var currentURL: String?
    
    func loadAndPlay(url: String) {
        guard currentURL != url else {
            player?.play()
            return
        }
        
        stopAndClean()
        
        guard let videoURL = URL(string: url) else { return }
        
        currentURL = url
        
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = isMuted

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
    
    func stopAndClean() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        currentURL = nil
    }
    
    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }
    
    deinit {
        stopAndClean()
    }
}

class ReelsViewModel: ObservableObject {
    @Published var reels: [Reel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showToast = false
    @Published var toastMessage: String?
    
    private let baseURL = "https://dfbf9976-22e3-4bb2-ae02-286dfd0d7c42.mock.pstmn.io"
    private let coreDataManager = CoreDataManager.shared
    
    func fetchReels() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let url = URL(string: "\(baseURL)/user/reels")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ReelsResponse.self, from: data)
            
            coreDataManager.saveReels(response.reels)
            
            await MainActor.run {
                reels = response.reels
            }
            
        } catch {
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
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func toggleLike(for reel: Reel) async {
        guard let index = reels.firstIndex(where: { $0.id == reel.id }) else { return }
        
        let oldState = reels[index].likedByUser
        let oldCount = reels[index].likeCount
        
        await MainActor.run {
            reels[index].likedByUser.toggle()
            reels[index].likeCount += reels[index].likedByUser ? 1 : -1
        }
        
        var updatedReel = reel
        updatedReel.likedByUser = !oldState
        updatedReel.likeCount += updatedReel.likedByUser ? 1 : -1
        coreDataManager.updateReel(updatedReel)
        
        do {
            if !oldState {
                try await likeReel(reelId: reel.id)
            } else {
                try await dislikeReel(reelId: reel.id)
            }
            
        } catch {
            await MainActor.run {
                reels[index].likedByUser = oldState
                reels[index].likeCount = oldCount
            }
            
            var revertedReel = reel
            revertedReel.likedByUser = oldState
            revertedReel.likeCount = oldCount
            coreDataManager.updateReel(revertedReel)
            
            await MainActor.run {
                showToastMessage("Unable to update like. Please try again")
            }
        }
    }
    
    private func likeReel(reelId: String) async throws {
        let url = URL(string: "\(baseURL)/user/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let likeRequest = ReelLikeRequest(like: true, reelsId: reelId)
        request.httpBody = try JSONEncoder().encode(likeRequest)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
    
    private func dislikeReel(reelId: String) async throws {
        let url = URL(string: "\(baseURL)/user/dislike")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let likeRequest = ReelLikeRequest(like: false, reelsId: reelId)
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
