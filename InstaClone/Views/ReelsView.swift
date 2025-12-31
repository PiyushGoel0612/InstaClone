//
//  ReelsView.swift
//  InstaClone
//
//  Created by Piyush Goel on 11/12/25.
//

import SwiftUI
import AVKit
internal import Combine

// ============================================================================
// Reels Screen (Instagram-style vertical video feed)
// ============================================================================

struct ReelsView: View {

    // Used to dismiss this view (navigation back)
    @Environment(\.dismiss) var dismiss

    // Shared login state (used for logout)
    @ObservedObject var viewModel: LoginViewModel

    // ViewModel responsible for fetching reels & handling likes
    @StateObject private var reelsViewModel = ReelsViewModel()

    // Currently visible reel index
    @State private var currentIndex: Int = 0

    // Scroll position binding for paging behavior
    @State private var scrollPosition: Int?

    var body: some View {

        // GeometryReader used to calculate full-screen reel height
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {

                    // ------------------------------------------------------------
                    // Top Navigation Bar
                    // ------------------------------------------------------------
                    HStack {
                        Text("Reels")
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .bold))

                        Spacer()

                        Button("Logout") {
                            viewModel.logout()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.black)

                    // ------------------------------------------------------------
                    // Main Content Area
                    // ------------------------------------------------------------
                    if reelsViewModel.isLoading {

                        // Loading State
                        Spacer()
                        ProgressView("Loading Reels...")
                            .foregroundColor(.white)
                        Spacer()

                    } else if let error = reelsViewModel.errorMessage {

                        // Error State
                        Spacer()
                        VStack(spacing: 16) {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()

                            Button("Retry") {
                                Task {
                                    await reelsViewModel.fetchReels()
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Spacer()

                    } else {

                        // --------------------------------------------------------
                        // Reels Feed (Vertical Paging)
                        // --------------------------------------------------------
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {

                                // Enumerated to track index for visibility
                                ForEach(
                                    Array(reelsViewModel.reels.enumerated()),
                                    id: \.element.id
                                ) { index, reel in

                                    ReelPlayerView(
                                        reel: reel,
                                        isVisible: currentIndex == index,
                                        onLike: {
                                            Task {
                                                await reelsViewModel.toggleLike(for: reel)
                                            }
                                        }
                                    )
                                    // Reel height slightly smaller than screen
                                    .frame(height: geometry.size.height - 150)
                                    .containerRelativeFrame(.vertical)
                                    .id(index)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $scrollPosition)

                        // Update currently visible reel index
                        .onChange(of: scrollPosition) { oldValue, newValue in
                            if let newValue = newValue {
                                currentIndex = newValue
                            }
                        }
                    }

                    // ------------------------------------------------------------
                    // Bottom Tab Bar
                    // ------------------------------------------------------------
                    HStack {
                        Spacer()

                        Button(action: { dismiss() }) {
                            VStack {
                                Image(systemName: "house")
                                    .font(.system(size: 24))
                                Text("Feed")
                                    .font(.caption)
                            }
                            .foregroundColor(.gray)
                        }

                        Spacer()

                        VStack {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 24))
                            Text("Reels")
                                .font(.caption)
                        }
                        .foregroundColor(.white)

                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .background(Color.black)
                }

                // ------------------------------------------------------------
                // Toast Message Overlay
                // ------------------------------------------------------------
                if reelsViewModel.showToast {
                    VStack {
                        Spacer().frame(height: 80)

                        Text(reelsViewModel.toastMessage ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(8)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: reelsViewModel.showToast)
                }
            }
        }
        .navigationBarBackButtonHidden(true)

        // Fetch reels when view appears
        .task {
            await reelsViewModel.fetchReels()
        }
    }
}

// ============================================================================
// Single Reel Video Player View
// ============================================================================

struct ReelPlayerView: View {

    let reel: Reel
    let isVisible: Bool
    let onLike: () -> Void

    // Manages AVPlayer lifecycle
    @StateObject private var playerManager = VideoPlayerManager()

    var body: some View {
        ZStack {

            // Video Player
            if let player = playerManager.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                Spacer()

                HStack(alignment: .bottom) {

                    // --------------------------------------------------------
                    // User Info
                    // --------------------------------------------------------
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            AsyncImage(url: URL(string: reel.userImage)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())

                            Text(reel.userName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }

                    Spacer()

                    // --------------------------------------------------------
                    // Action Buttons (Like, Comment, Share, Mute)
                    // --------------------------------------------------------
                    VStack(spacing: 20) {

                        // Like Button
                        Button(action: onLike) {
                            VStack(spacing: 4) {
                                Image(systemName: reel.likedByUser ? "heart.fill" : "heart")
                                    .font(.system(size: 32))
                                    .foregroundColor(reel.likedByUser ? .red : .white)

                                Text("\(reel.likeCount)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }

                        // Comment Placeholder
                        VStack(spacing: 4) {
                            Image(systemName: "message")
                                .font(.system(size: 28))
                                .foregroundColor(.white)

                            Text("0")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        // Share Placeholder
                        VStack(spacing: 4) {
                            Image(systemName: "paperplane")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }

                        // Mute / Unmute
                        Button(action: {
                            playerManager.toggleMute()
                        }) {
                            Image(
                                systemName: playerManager.isMuted
                                ? "speaker.slash.fill"
                                : "speaker.wave.2.fill"
                            )
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
        }

        // Play / stop video based on visibility
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                playerManager.loadAndPlay(url: reel.reelVideo)
            } else {
                playerManager.stopAndClean()
            }
        }

        // Initial play if already visible
        .onAppear {
            if isVisible {
                playerManager.loadAndPlay(url: reel.reelVideo)
            }
        }

        // Cleanup when leaving screen
        .onDisappear {
            playerManager.stopAndClean()
        }
    }
}

#Preview {
    ReelsView(viewModel: LoginViewModel())
}
