
//
//  PostDetailView.swift
//  Insect-detector-ios
//
//  Created by Umair Rajput on 1/19/25.
//

import SwiftUI
import CocoaLumberjack

struct PostDetailView: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var commonViewModel: CommonViewModel


    @State private var commentText: String = ""
    @State private var showLoginAlert: Bool = false
    @State  var userId: Int? = 0
    @State var isLiked :Bool = false
    @State var currentLikeId : Int = 0
    @State var isFollowing :Bool = false

    
    @State var showReportDialog =  false
    @State var showUserReoprtDialog =  false
    
    var body: some View {
        VStack() {
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
                    Text(postViewModel.selectedPost?.title ?? "Unknown")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .padding(.leading,20)
                    Spacer()
                }
                Spacer()
                Menu {
                    Button("Report User") {
                        userViewModel.reportUser(userId: Int(postViewModel.selectedPost?.userId ?? 0))
                        showUserReoprtDialog =  true
                    }
                    
                    Button("Report Post") {
                        showReportDialog = true
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
                    if let selectedPost = postViewModel.selectedPost {
                        // Main Post Content
                        MainPostView(
                            image: selectedPost.imageUrl ?? "defaultImageURL",
                            profilePic: selectedPost.userImage ?? "https://www.rattanhospital.in/wp-content/uploads/2020/03/user-dummy-pic.png",
                            name: selectedPost.userName ?? "Anonymous",
                            description: selectedPost.descriptionText ?? "No description available",
                            time: selectedPost.createdAt.formattedDate(),
                            likeCount: Int(selectedPost.likeCount),
                            commentCount: Int(selectedPost.commentCount),
                            shareCount: Int(selectedPost.watcherCount),
                            isLiked: $isLiked,
                            isFollowing: $isFollowing // New binding for follow/unfollow state
                        ) {
                            // Toggle like action
                            if userId == 0 {
                                showLoginAlert = true
                            } else {
                                toggleLike(for: Int(selectedPost.postId))
                            }
                        } toggleFollowAction: {
                            // Toggle follow/unfollow action
                            toggleFollow(userId: userId ?? 0)
                 
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
                                    imageUrl: userViewModel.currentUser?.imageUrl ?? "defaultProfilePicURL"
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
            .clipped()
        

            Divider()

            // Comment Input
            CommentInputView(imageUrl: userViewModel.currentUser?.imageUrl ?? "defaultProfilePicURL", commentText: $commentText) {
                if userId == 0 {
                    showLoginAlert = true
                } else {
                    guard let postId = postViewModel.selectedPost?.postId, let userId = userId, !commentText.isEmpty else {
                        DDLogError("Failed to add comment: postId, userId, or commentText is invalid")
                        return
                    }

                    postViewModel.addComment(postId:Int(postId), userId: userId, str: commentText)
                    commentText = ""
                }
            }
   
        }
        .overlay(
            ReportDialogView(postViewModel: postViewModel, navigationManager: navigationManager, isPresented: $showReportDialog)
         )
        .background(Color.white.ignoresSafeArea())
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("Login Required"),
                message: Text("You need to log in to like or comment on this post."),
                primaryButton: .default(Text("Login"), action: {
    
                    commonViewModel.selectedTab = .profile
                    navigationManager.pop()
                }),
                secondaryButton: .cancel()
            )
        }

        .onChange(of: userViewModel.isReportSuccess){ newValue in
            if newValue
            {
                AlertManager.shared.showAlert(
                    title: "Report",
                    message: "User successfully reported. Thank you for feebback!",
                    primaryButtonTitle: "OK",
                    primaryAction: {
                        navigationManager.pop()
                        userViewModel.isReportSuccess =  false
                    },
                    showSecondaryButton: false
                )
            }

        }
        .onChange(of: postViewModel.isReportSuccess){ newValue in
            if newValue
            {
                AlertManager.shared.showAlert(
                    title: "Report",
                    message: "Post successfully reported. Thank you for feebback!",
                    primaryButtonTitle: "OK",
                    primaryAction: {
                       // navigationManager.pop()
                        postViewModel.isReportSuccess =  false
                    },
                    showSecondaryButton: false
                )

            }
        }
        .onAppear {

            if let postId = postViewModel.selectedPost?.postId {
                postViewModel.addWatcherCount(postId: Int(postId))
                postViewModel.fetchComments(for: Int(postId) )
            }
            setupView()
            
            let userIdToCheck = postViewModel.selectedPost?.userId ?? 0

            let isFollowingUser = userViewModel.following.contains(where: { $0.followingUser.userId == userIdToCheck })

            if isFollowingUser {
                DDLogDebug("The user is in the following list.")
                isFollowing = true
            } else {
                DDLogDebug("The user is not in the following list.")
                isFollowing = false
            }

        }
    }
    
    
     private func setupView() {
        guard let userId: Int = UserDefaultManager.shared.get(forKey: UserDefaultManager.Key.currentUser) else {
            DDLogError("User ID is not available.")
            return
        }
        self.userId = userId

        guard let postId = postViewModel.selectedPost?.postId else {
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
                    self.postViewModel.selectedPost?.likeCount = max((self.postViewModel.selectedPost?.likeCount ?? 1) - 1, 0)
                    self.postViewModel.updatePost(
                        postId: Int(self.postViewModel.selectedPost?.postId ?? 0),
                        likeCount: Int(self.postViewModel.selectedPost?.likeCount ?? 0),
                        commentCount: Int(self.postViewModel.selectedPost?.commentCount ?? 0)
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
                    self.postViewModel.selectedPost?.likeCount = (self.postViewModel.selectedPost?.likeCount ?? 0) + 1
                    self.postViewModel.updatePost(
                        postId: Int(self.postViewModel.selectedPost?.postId ?? 0),
                        likeCount: Int(self.postViewModel.selectedPost?.likeCount ?? 0),
                        commentCount: Int(self.postViewModel.selectedPost?.commentCount ?? 0)
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
    
    func toggleFollow(userId: Int) {
        guard let postUserId = postViewModel.selectedPost?.userId else {
            DDLogError("Post ID is not available.")
            return
        }
        if isFollowing {
            userViewModel.unfollowUser(followerUserId: "\(userId)", followedUserId: "\(postUserId)")
            isFollowing.toggle()
        } else {
            userViewModel.followUser(followerUserId: "\(userId)", followedUserId: "\(postUserId)")
            isFollowing.toggle()
        }
    }

    
    func checkFollowing(){
        
    }
}

struct ReportDialogView: View {
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var navigationManager: NavigationManager
    @Binding var isPresented: Bool
    @State private var selectedReason: ReportReason? = nil

    enum ReportReason: String, CaseIterable {
        case spam = "It's Spam"
        case nudity = "Nudity or sexual activity"
        case hateSpeech = "Hate speech or symbols"
        case falseInfo = "False information"
        case other = "Any other"
    }

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    Text("Why are you reporting this?")
                        .font(.headline)
                        .foregroundColor(.black)

                    VStack(alignment: .leading) {
                        ForEach(ReportReason.allCases, id: \.self) { reason in
                            HStack {
                                Image(systemName: selectedReason == reason ? "largecircle.fill.circle" : "circle")
                                    .foregroundColor(ColorHelper.primary.color)
                                Text(reason.rawValue)
                                    .font(.body)
                                    .foregroundColor(.black)
                            }
                            .padding(.vertical, 4)
                            .onTapGesture {
                                selectedReason = reason
                            }
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundColor(ColorHelper.primary.color)

                        Spacer()

                        Button("OK") {
                            if let reason = selectedReason {
                                handleReport(reason: reason)
                                isPresented = false
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal,35)
                        .padding(.vertical,12)
                        .background(selectedReason == nil ? Color.gray : ColorHelper.primary.color)
                        .cornerRadius(15)
                        .disabled(selectedReason == nil)
                    }
                    .padding()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding(.horizontal, 40)
            }
            .animation(.easeInOut, value: isPresented)
            .transition(.opacity)
        }
    }

    private func handleReport(reason: ReportReason) {
        guard let postId = postViewModel.selectedPost?.postId,
              let userId = postViewModel.selectedPost?.userId else {
            print("Error: Missing post or user ID")
            return
        }

        print("User selected reason: \(reason.rawValue)")
        postViewModel.reportPost(postId: Int(postId))
        postViewModel.deletePost(postId: Int(postId), userId: Int(userId))
        postViewModel.refreshPosts()
        navigationManager.pop()
    }
}


struct MainPostView: View {
    var image: String
    var profilePic: String
    var name: String
    var description: String
    var time: String
    var likeCount: Int
    var commentCount: Int
    var shareCount: Int
    @Binding var isLiked: Bool
    @Binding var isFollowing: Bool // State for follow/unfollow
    var toggleLikeAction: () -> Void
    var toggleFollowAction: () -> Void // Action for follow/unfollow

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if(profilePic == ""){
                    MyRemoteImage(urlString: "https://www.rattanhospital.in/wp-content/uploads/2020/03/user-dummy-pic.png")
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .padding(.leading, 15)
                }else {
                    MyRemoteImage(urlString: profilePic)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .padding(.leading, 15)
                }
    

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

                // Follow/Unfollow Button
        
                Button(action: toggleFollowAction) {
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .font(.custom(FontHelper.medium.rawValue, size: 14))
                        .foregroundColor(isFollowing ? ColorHelper.primary.color : .white)
                        .padding(.horizontal, 10) // Reduced horizontal padding
                        .padding(.vertical, 6) // Adjust vertical padding for better proportions
                        .frame(minWidth: 80, maxWidth: 100) // Set a fixed width range for the button
                        .background(isFollowing ? Color.clear : ColorHelper.primary.color) // No inner color when following
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isFollowing ? ColorHelper.primary.color : Color.clear, lineWidth: 1) // Stroke for Unfollow
                        )
                        .cornerRadius(10)
                }
                .padding(.trailing, 10) // Reduced trailing padding


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


struct LikeView: View {
    @Binding var isLiked: Bool
    var count: String
    var action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Image(isLiked ? ImageResource.redHeart : ImageResource.like)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(isLiked ? .red : .white)
                .onTapGesture {
                    action()
                }
            Text(count)
                .foregroundColor(.white)
            Spacer()
        }
        .frame(width: 100, height: 35)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#424242"), Color(hex: "#404040"),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.55)
        )
        .cornerRadius(20)
    }
}





// MARK: - Post Header View
struct PostHeaderView: View {
    var body: some View {
        HStack {
            Image("dummy_img")
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text("Richard Larsson")
                    .font(.headline)
                Text("2 hours ago")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: {
                // Handle follow action
            }) {
                Text("Follow")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Post Description View
struct PostDescriptionView: View {
    let description: String
    
    var body: some View {
        Text(description)
            .font(.body)
            .padding(.horizontal)
    }
}

// MARK: - Post Image View
struct PostImageView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: 300)
            .cornerRadius(12)
            .padding(.horizontal)
    }
}

// MARK: - Post Actions View
struct PostActionsView: View {
    var body: some View {
        HStack(spacing: 40) {
            PostActionButton(icon: "heart.fill", count: "1256", isSelected: true)
            PostActionButton(icon: "bubble.left", count: "567", isSelected: false)
            PostActionButton(icon: "arrowshape.turn.up.right", count: "56", isSelected: false)
        }
        .padding(.vertical)
    }
}

// MARK: - Post Action Button
struct PostActionButton: View {
    let icon: String
    let count: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .red : .gray)
            Text(count)
                .font(.subheadline)
        }
    }
}

// MARK: - Comment View
struct CommentViewForDetails: View {
    let username: String
    let comment: String
    let timeAgo: String
    let imageUrl : String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MyRemoteImage(urlString: imageUrl)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(username)
                        .font(.headline)
                    Spacer()
                    Text(timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Text(comment)
                    .font(.body)
                    .padding(.bottom,20)
//                HStack {
//                    Image(systemName: "heart.fill")
//                        .foregroundColor(.red)
//
////                    Text(likeCount)
////                        .font(.subheadline)
//
//                    Button(action: {
//                        // Handle reply action
//                    }) {
//                        Text("Reply")
//                            .font(.subheadline)
//                            .foregroundColor(.blue)
//                    }
//                    .padding(.leading,20)
//                    Spacer()
//                }
//                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Comment Input View
struct CommentInputView: View {
    let imageUrl: String
    @Binding var commentText: String
    var postAction: () -> Void
    
    var body: some View {
        HStack {
            MyRemoteImage(urlString: imageUrl)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            TextField("Your Comment...", text: $commentText)
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            
            Button(action: postAction) {
                Text("Post")
                    .foregroundColor(.blue)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - Preview
struct PostDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PostDetailView(navigationManager: NavigationManager(), postViewModel: PostViewModel(),userViewModel: UserViewModel(),commonViewModel: CommonViewModel())
    }
}
