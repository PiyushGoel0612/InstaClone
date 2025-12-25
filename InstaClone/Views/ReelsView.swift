//
//  ReelsView.swift
//  InstaClone
//
//  Created by Piyush Goel on 11/12/25.
//

import SwiftUI
import AVKit
internal import Combine

struct ReelsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LoginViewModel
    @StateObject private var reelsViewModel = ReelsViewModel()
    @State private var currentIndex: Int = 0
    @State private var scrollPosition: Int?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                    
                    // Content
                    if reelsViewModel.isLoading {
                        Spacer()
                        ProgressView("Loading Reels...")
                            .foregroundColor(.white)
                        Spacer()
                        
                    } else if let error = reelsViewModel.errorMessage {
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
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(reelsViewModel.reels.enumerated()), id: \.element.id) { index, reel in
                                    ReelPlayerView(
                                        reel: reel,
                                        isVisible: currentIndex == index,
                                        onLike: {
                                            Task {
                                                await reelsViewModel.toggleLike(for: reel)
                                            }
                                        }
                                    )
                                    .frame(height: geometry.size.height - 150)
                                    .containerRelativeFrame(.vertical)
                                    .id(index)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $scrollPosition)
                        .onChange(of: scrollPosition) { oldValue, newValue in
                            if let newValue = newValue {
                                currentIndex = newValue
                            }
                        }
                    }
                    
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
        .task {
            await reelsViewModel.fetchReels()
        }
    }
}

struct ReelPlayerView: View {
    let reel: Reel
    let isVisible: Bool
    let onLike: () -> Void
    
    @StateObject private var playerManager = VideoPlayerManager()
    
    var body: some View {
        ZStack {
            if let player = playerManager.player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
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
                    
                    VStack(spacing: 20) {
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
                        
                        VStack(spacing: 4) {
                            Image(systemName: "message")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                            
                            Text("0")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Image(systemName: "paperplane")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            playerManager.toggleMute()
                        }) {
                            Image(systemName: playerManager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
        }
        .onChange(of: isVisible) { oldValue, newValue in
            if newValue {
                playerManager.loadAndPlay(url: reel.reelVideo)
            } else {
                playerManager.stopAndClean()
            }
        }
        .onAppear {
            if isVisible {
                playerManager.loadAndPlay(url: reel.reelVideo)
            }
        }
        .onDisappear {
            playerManager.stopAndClean()
        }
    }
}

#Preview {
    ReelsView(viewModel: LoginViewModel())
}
