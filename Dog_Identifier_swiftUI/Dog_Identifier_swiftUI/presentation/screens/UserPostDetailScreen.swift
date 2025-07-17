
//
//  PostDetailView.swift
//  Insect-detector-ios
//
//  Created by Umair Rajput on 1/19/25.
//

import SwiftUI
import CocoaLumberjack

struct UserPostDetailScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel

    @State private var commentText: String = ""
    @State private var showLoginAlert: Bool = false
    @State  var userId: Int? = 0
    @State var isLiked :Bool = false
    @State var currentLikeId : Int = 0

    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            // Navigation Bar
            HStack {
                HStack {
                    Button(action: {
                        navigationManager.pop()
                    }) {
                        Image("backBtn")
                            .foregroundColor(.orange)
                            .font(.title2)
                    }
                    Text(postViewModel.selectedUserPost?.title ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .padding(.leading,20)
                    Spacer()
                }
                Spacer()
                Menu {
                  Button("Delete Post") {
                      postViewModel.deletePost(postId: Int(postViewModel.selectedUserPost?.postId ?? 0), userId: userId ?? 0)
                    }

                } label: {
                    Image(ImageResource.menu)
                        .resizable()
                        .frame(width: 30, height: 30)
                }
            }
            .padding()

            ScrollView {
                VStack(spacing: 16) {
                    if let selectedUserPost = postViewModel.selectedUserPost {
                        // Main Post Content
                        UserMainPostView(
                            image: selectedUserPost.imageUrl ?? "defaultImageURL",
                            profilePic: selectedUserPost.userImage ?? "defaultProfilePicURL",
                            name: selectedUserPost.userName ?? "Anonymous",
                            description: selectedUserPost.descriptionText ?? "No description available",
                            time: selectedUserPost.createdAt.formattedDate(),
                            likeCount: Int(selectedUserPost.likeCount),
                            commentCount: Int(selectedUserPost.commentCount),
                            shareCount: Int(selectedUserPost.watcherCount),
                            isLiked: $isLiked
                        ) {
                            if userId == 0 {
                                showLoginAlert = true
                            } else {
                                toggleLike(for: Int(selectedUserPost.postId))
                            }
                        }
                        .padding(.top,20)

                        Divider()

                        // Comments Section
                        if postViewModel.selectedPostComments.isEmpty {
                            Text("No comments yet.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(postViewModel.selectedPostComments, id: \.commentId) { comment in
                                CommentViewForDetails(
                                    username: comment.userName,
                                    comment: comment.commentText,
                                    timeAgo: comment.createdAt.formattedDate(),
                                    imageUrl: comment.userImageUrl
                                )
                                Divider()
                            }
                        }
                    } else {
                        Text("No post selected.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }

            Divider()

            // Comment Input
            CommentInputView(imageUrl: postViewModel.selectedUserPost?.userImage ?? "defaultProfilePicURL", commentText: $commentText) {
                if userId == 0 {
                    showLoginAlert = true
                } else {
                    guard let postId = postViewModel.selectedUserPost?.postId, let userId = userId, !commentText.isEmpty else {
                        DDLogError("Failed to add comment: postId, userId, or commentText is invalid")
                        return
                    }

                    postViewModel.addComment(postId:Int(postId), userId: userId, str: commentText)
                    commentText = ""
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("Login Required"),
                message: Text("You need to log in to like or comment on this post."),
                primaryButton: .default(Text("Login"), action: {
                 //   navigationManager.navigateToLogin()
                }),
                secondaryButton: .cancel()
            )
        }
        .onChange(of: postViewModel.isReportSuccess){ newValue in
            if newValue
            {
                AlertManager.shared.showAlert(
                    title: "Alert",
                    message: "Post successfully deleted.",
                    primaryButtonTitle: "OK",
                    primaryAction: {
                        navigationManager.pop()
                        postViewModel.isReportSuccess =  false
                    },
                    showSecondaryButton: false
                )

            }
        }
        .onAppear {
           
            if let postId = postViewModel.selectedUserPost?.postId {
                postViewModel.addWatcherCount(postId: Int(postId))
                postViewModel.fetchComments(for: Int(postId) )
            }
            setupView()
        }
    }
    
    
     private func setupView() {
        guard let userId: Int = UserDefaultManager.shared.get(forKey: UserDefaultManager.Key.currentUser) else {
            DDLogError("User ID is not available.")
            return
        }
        self.userId = userId

        guard let postId = postViewModel.selectedUserPost?.postId else {
            DDLogError("Post ID is not available.")
            return
        }

        DDLogDebug("Fetching likes for post ID: \(postId)")

        postViewModel.getLikes(postId: Int(postId)) { success in
            guard success else {
                DDLogError("Failed to fetch likes. Aborting further processing.")
                return
            }

            // Now it's safe to check if the user has liked the post
            if let userLike = self.postViewModel.likes.first(where: { $0.postId == postId && $0.userId == userId }) {
                self.isLiked = true
                self.currentLikeId = userLike.likeId
                DDLogDebug("Post is liked. Like ID: \(userLike.likeId)")
            } else {
                self.isLiked = false
                self.currentLikeId = 0
                DDLogDebug("Post is not liked.")
            }
        }
    }

    private func toggleLike(for postId: Int?) {
        guard let postId = postId, let userId = userId else {
            DDLogError("Post ID or User ID is nil during like/unlike action.")
            return
        }

        if isLiked {
            // Unlike the post
            postViewModel.unlikePost(likeId: currentLikeId, userId: userId) { success in
                if success {
                    self.postViewModel.selectedUserPost?.likeCount = max((self.postViewModel.selectedUserPost?.likeCount ?? 1) - 1, 0)
                    self.postViewModel.updatePost(
                        postId: Int(self.postViewModel.selectedUserPost?.postId ?? 0),
                        likeCount: Int(self.postViewModel.selectedUserPost?.likeCount ?? 0),
                        commentCount: Int(self.postViewModel.selectedUserPost?.commentCount ?? 0)
                    )
                    self.isLiked = false
                    DDLogInfo("Successfully unliked post \(postId)")
                } else {
                    DDLogError("Failed to unlike post \(postId)")
                }
            }
        } else {
            // Like the post
            postViewModel.likePost(postId: postId, userId: userId) { success, newLikeId in
                if success {
                    self.postViewModel.selectedUserPost?.likeCount = (self.postViewModel.selectedUserPost?.likeCount ?? 0) + 1
                    self.postViewModel.updatePost(
                        postId: Int(self.postViewModel.selectedUserPost?.postId ?? 0),
                        likeCount: Int(self.postViewModel.selectedUserPost?.likeCount ?? 0),
                        commentCount: Int(self.postViewModel.selectedUserPost?.commentCount ?? 0)
                    )
                    self.currentLikeId = newLikeId ?? 0
                    self.isLiked = true
                    DDLogInfo("Successfully liked post \(postId)")
                } else {
                    DDLogError("Failed to like post \(postId)")
                }
            }
        }
    }
}

struct UserMainPostView: View {
    var image: String
    var profilePic: String
    var name: String
    var description: String
    var time: String
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    @Binding var isLiked: Bool
    var toggleLikeAction: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                MyRemoteImage(urlString: profilePic)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .padding(.leading, 15)

                VStack(alignment: .leading) {
                    Spacer()
                    Text(name)
                        .font(.custom(FontHelper.bold.rawValue, size: 16))
                        .foregroundColor(ColorHelper.darkText.color)
                        .padding(.bottom, 1)
                        .lineLimit(1)

                    Text(time)
                        .font(.custom(FontHelper.medium.rawValue, size: 15))
                        .foregroundColor(ColorHelper.lightText.color)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.leading, 10)
                Spacer()
//                Image(ImageResource.menu)
//                    .resizable()
//                    .frame(width: 30, height: 30)
//                    .tint(.white)
//                    .padding(.trailing, 30)
            }
            .padding(.top, 10)

            Text(description)
                .font(.custom(FontHelper.medium.rawValue, size: 14))
                .foregroundColor(ColorHelper.darkText.color)
                .padding(.horizontal, 15)

            ZStack(alignment: .bottom) {
                MyRemoteImage(urlString: image)
                    .frame(width: .infinity, height: 300)
                    .cornerRadius(15)
                    .clipped()

                HStack {
                    LikeView(isLiked: $isLiked, count: "\(likeCount)", action: toggleLikeAction)
                    LikeCommentView(image: ImageResource.message, count: "\(commentCount)", iconSize: 20, width: 100, height: 35, textSize: 16)
                    LikeCommentView(image: ImageResource.send, count: "\(shareCount)", iconSize: 20, width: 100, height: 35, textSize: 16)
                }
                .padding(.bottom, 20)
                .cornerRadius(8)
            }
        }
        .frame(height: 380)
        .padding(.horizontal, 10)
    }
}




// MARK: - Preview
struct UserPostDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        UserPostDetailScreen(navigationManager: NavigationManager(), postViewModel: PostViewModel())
    }
}
