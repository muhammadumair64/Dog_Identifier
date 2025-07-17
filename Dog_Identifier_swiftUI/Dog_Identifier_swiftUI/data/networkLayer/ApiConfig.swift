//
//  ApiConfig.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 06/01/2025.

struct ApiConfig {

    static let baseURL = "https://iobits.xyz/Social-Backend-dogs-1.0.0-SNAPSHOT/"
 
    struct Endpoints {
        // User APIs
        static let checkUserAvailable = "api/user/available"         // GET (uid as query)
        static let createUser = "api/user"                           // POST (Body: User)
        static let getUserByUid = "api/user/current_user"            // GET (uid as query)
        static let getUserByUserId = "api/user"                      // GET (userId as query)
        static let getAllUsers = "api/user/all"                      // GET
        static let reportUser = "api/user/report"                    // PUT (userId as query)
        static let updateNotificationToken = "api/update_token"      // PUT (token, userId as query)

        // Image APIs
        static let uploadImage = "api/image/upload"                  // PUT (Multipart)

        // Post APIs
        static let createPost = "api/post"                           // POST (Body: CreatePostModel)
        static let getPostByPostId = "api/post"                      // GET (postId as query)
        static func getPostsByUserId(userId: Int) -> String {
            return "api/post/\(userId)"
        }
       // GET (Path: userId)
        static let getPosts = "api/post/all"                         // GET (page, size as query)
        static let addWatcherCount = "api/post/watcher"              // POST (postId as query)
        static let reportPost = "api/post/report"                    // PUT (postId as query)
        static let deletePost = "api/post"                           // DELETE (postId as query)

        // Comments APIs
        static let addComment = "api/comments"                       // POST (Body: CommentRequestModel)
        static let getPostComments = "api/comments"                  // GET (postId as query)
        static let deleteComment = "api/comments"                    // DELETE (commentId as query)

        // Likes APIs
        static let like = "api/like"                                 // POST (Body: LikeRequestModel)
        static let unlike = "api/like"                               // DELETE (likeId, userId as query)
        static let getPostLikes = "api/like"                         // GET (postId as query)
        static let getUserLikes = "api/like/user_likes"              // GET (postId as query)

        // Follow/Unfollow APIs
        static let follow = "api/follower"                           // POST (followerUserId, followedUserId as query)
        static let unFollow = "api/unfollow"                         // POST (followerUserId, followedUserId as query)
        static let getFollowers = "api/follower"                    // GET (userId as query)
        static let getFollowing = "api/following"                   // GET (userId as query)
    }
}
