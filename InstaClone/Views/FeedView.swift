//
//  FeedView.swift
//  InstaClone
//
//  Created by Piyush Goel on 13/12/25.
//

import SwiftUI
internal import Combine

// ============================================================================
// Feed View
// ============================================================================

struct FeedView: View {

    // Used to dismiss this view on logout
    @Environment(\.dismiss) var dismiss

    // Shared LoginViewModel from LoginView
    @ObservedObject var viewModel: LoginViewModel

    // ViewModel for reels navigation
    @StateObject var reelsViewModel = ReelsViewModel()

    // ViewModel for feed data
    @StateObject private var feedViewModel = FeedViewModel()

    // Controls navigation to Reels screen
    @State private var atReels = false

    var body: some View {
        ZStack {
            
            Color.black
                .ignoresSafeArea()
                .opacity(0.9)

            VStack {

                // ------------------------------------------------------------
                // Top Header
                // ------------------------------------------------------------
                HStack {
                    Text("Instagram")
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold, design: .serif))

                    Spacer()

                    // Logout button
                    Button("Logout") {
                        viewModel.logout()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                .padding()

                // ------------------------------------------------------------
                // Feed Content
                // ------------------------------------------------------------
                VStack {

                    // If still fetching data
                    if feedViewModel.isLoading {
                        Spacer()

                        ProgressView("Fetching Feed...")
                            .foregroundColor(.white)
                            .opacity(0.8)

                        Spacer()

                    // Error state
                    } else if let errorMessage = feedViewModel.errorMessage {
                        VStack(spacing: 16) {
                            Spacer()

                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding()

                            // Retry button
                            Button("Retry") {
                                Task {
                                    await feedViewModel.fetchFeed()
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Spacer()
                        }

                    // After fetching is complete
                    } else {
                        VStack {
                            ScrollView {
                                LazyVStack(spacing: 0) {

                                    // Render each post
                                    ForEach(feedViewModel.posts) { post in
                                        PostView(
                                            post: post,
                                            onLike: {
                                                Task {
                                                    await feedViewModel.toggleLike(for: post)
                                                }
                                            }
                                        )
                                        // Seperate each post with a "Divider"
                                        Divider()
                                    }
                                }
                            }
                            // Pull-to-refresh functionality
                            .refreshable {
                                await feedViewModel.fetchFeed()
                            }
                        }
                    }

                    // ------------------------------------------------------------
                    // Toast Message Overlay
                    // ------------------------------------------------------------
                    if feedViewModel.showToast {
                        VStack {
                            Spacer()

                            Text(feedViewModel.toastMessage ?? "")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red.opacity(0.9))
                                .cornerRadius(8)
                                .padding(.horizontal)

                            Spacer()
                        }
                        .frame(maxHeight: 70, alignment: .top)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut, value: feedViewModel.showToast)
                    }
                }
                // Fetch feed when view appears
                .task {
                    await feedViewModel.fetchFeed()
                }

                // ------------------------------------------------------------
                // Bottom Navigation Bar
                // ------------------------------------------------------------
                HStack {
                    Spacer()

                    // Feed tab (current)
                    Button(action: {
                        // Already on Feed
                    }) {
                        VStack {
                            Image(systemName: "house.fill")
                                .font(.system(size: 24))
                            Text("Feed")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                    }

                    Spacer()

                    // Reels tab
                    Button(action: {
                        atReels = true
                    }) {
                        VStack {
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 24))
                            Text("Reels")
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(.bottom, 1)
                .padding(.top, 25)
                .background(Color.black)
            }
        }
        .navigationBarBackButtonHidden(true)

        // Navigation to Reels screen
        .navigationDestination(isPresented: $atReels) {
            ReelsView(
                viewModel: viewModel
            )
        }
    }
}

// ============================================================================
// Post View
// ============================================================================

// View responsible for a single post
struct PostView: View {

    let post: Post
    let onLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // ------------------------------------------------------------
            // User Info Row
            // ------------------------------------------------------------
            HStack(spacing: 10) {
                
                // User profile image
                AsyncImage(url: URL(string: post.userImage)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())

                // User name who owns the post
                Text(post.userName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // ------------------------------------------------------------
            // Post Image
            // ------------------------------------------------------------
            AsyncImage(url: URL(string: post.postImage)) { phase in
                switch phase {
                // While the image is loading
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 400)
                        .overlay(ProgressView())
                    
                // After the image has loaded successfully
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()

                // On Failure display a placeholder
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 400)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )

                @unknown default:
                    EmptyView()
                }
            }

            // ------------------------------------------------------------
            // Action Buttons
            // ------------------------------------------------------------
            HStack(spacing: 16) {

                // Like button, toggles colour based on like state
                Button(action: onLike) {
                    Image(systemName: post.likedByUser ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(post.likedByUser ? .red : .white)
                }

                Image(systemName: "message")
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                Image(systemName: "paperplane")
                    .font(.system(size: 24))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "bookmark")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // ------------------------------------------------------------
            // Like Count & Comments
            // ------------------------------------------------------------
            Text("\(post.likeCount) likes")
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal)
                .foregroundColor(.white)

            Text("View all comments")
                .font(.system(size: 14))
                .padding(.horizontal)
                .padding(.bottom, 8)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack {
        FeedView(
            viewModel: LoginViewModel()
        )
    }
}
