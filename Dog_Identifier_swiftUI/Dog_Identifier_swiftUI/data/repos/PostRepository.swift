import Foundation
import SwiftUI
import Combine
import CocoaLumberjack

class PostRepository {
    // Fetch posts from the server or Core Data based on availability
    func getPosts(page: Int, size: Int, completion: @escaping (Result<[PostEntity], NetworkError>) -> Void) {
        let queryParameters: [String: String] = [
            "page": "\(page)",
            "size": "\(size)"
        ]

        // Perform network request
        NetworkingManager.shared.request(
            
            endpoint: ApiConfig.Endpoints.getPosts,
            method: "GET",
            queryParameters: queryParameters
        ) { (result: Result<PostBaseModel, NetworkError>) in
            switch result {
            case .success(let postBaseModel):
                // Save posts to Core Data
                CoreDataManager.shared.savePosts(posts: postBaseModel.posts, page: page)
                
                // Fetch posts from Core Data for consistency
                let fetchedPosts = CoreDataManager.shared.fetchPosts(page: page, limit: size)
                completion(.success(fetchedPosts))
                
            case .failure(let error):
                completion(.failure(error))
                DDLogError("API ERROR = \(error)")
            }
        }
    }
    
    func getUserPosts(userId: Int, completion: @escaping (Result<[UserPosts], NetworkError>) -> Void) {
        let queryParameters: [String: String] = [
            "userId": "\(userId)"
        ]
        DDLogDebug("Before user post API call")

        NetworkingManager.shared.request(
            endpoint: ApiConfig.Endpoints.getPostsByUserId(userId: userId),
            method: "GET",
            queryParameters: queryParameters
        ) { (result: Result<PostBaseModel, NetworkError>) in
            switch result {
            case .success(let postBaseModel):
                DDLogDebug("User post API success: \(postBaseModel.posts.count) posts fetched")
                CoreDataManager.shared.deleteAllUserPosts()
                // Save posts to Core Data
                DDLogVerbose("Saving posts to Core Data")
                CoreDataManager.shared.saveUserPosts(posts: postBaseModel.posts) { success in
                    guard success else {
                        DDLogError("Failed to save posts to Core Data")
                        completion(.failure(.timeoutError))
                        return
                    }

                    // Fetch posts from Core Data after saving
                    DDLogVerbose("Fetching posts from Core Data after saving")
                    let fetchedPosts = CoreDataManager.shared.fetchUserPosts()

                    // Return the result on the main thread
                    DispatchQueue.main.async {
                        completion(.success(fetchedPosts))
                        DDLogDebug("Fetched \(fetchedPosts.count) posts from Core Data")
                    }
                }

            case .failure(let error):
                DDLogError("API error: \(error)")
                completion(.failure(error))
            }
        }
    }

    
    func createPost(userId: Int, postModel: CreatePostModel, completion: @escaping (Result<ResponsePostModel, NetworkError>) -> Void) {
        // Ensure the userId is passed as a query parameter
        let url = ApiConfig.Endpoints.createPost + "?userId=\(userId)"

        // Convert the postModel into JSON
        let parameters: [String: Any] = [
            "uid": postModel.uid,
            "title": postModel.title,
            "description": postModel.description,
            "imageUrl": postModel.imageUrl,
            "location": postModel.location,
            "lat": postModel.lat,
            "lng": postModel.lng,
            "category": postModel.category ?? "" // Handle optional category
        ]
        
        // Assuming NetworkingManager sends data as JSON in the body and supports query parameters
        NetworkingManager.shared.request(
            endpoint: url, // Add userId in the query string
            method: "POST",
            parameters: parameters, // Post body parameters
            completion: { (result: Result<ResponsePostModel, NetworkError>) in
                switch result {
                case .success(let responsePostModel):
                    // Handle success, maybe save the new post locally or update the UI
                    completion(.success(responsePostModel))
                case .failure(let error):
                    // Log and handle failure
                    DDLogError("Failed to create post: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        )
    }

    
    func uploadImage(image: UIImage, completion: @escaping (Result<String, NetworkError>) -> Void) {
            // Use the UploadImageManager to upload the image
        UploadImageManager.shared.uploadImageCall(imageView: image, fileName: "image.png", paramName: "image") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    DDLogInfo("[INFO]: Image upload completed successfully in Repository.")
                    completion(.success(success))
                case .failure(let error):
                    DDLogError("[ERROR]: Image upload failed in Repository with error: \(error.description)")
                    completion(.failure(error))
                }
            }
        }
    }

    
    
    func addWatcherCount(postId: Int, completion: @escaping (Result<Int, NetworkError>) -> Void) {
        let queryParameters: [String: String] = [
            "postId": "\(postId)"
        ]
        // Perform network request using NetworkingManager
        NetworkingManager.shared.request(
            endpoint: ApiConfig.Endpoints.addWatcherCount,
            method: "POST",
            queryParameters: queryParameters
        ) { (result: Result<Int, NetworkError>) in
            switch result {
            case .success(let Int):
                // Log the fetched comments
                DDLogInfo("Fetched comments for post ID \(postId) : Status Code: \(Int)")
                
                // Return the comments via the completion handler
                completion(.success(Int))
                
            case .failure(let error):
                // Log error details
                DDLogError("Failed to fetch comments for post ID \(postId): \(error)")
                
                // Return the error via the completion handler
                completion(.failure(error))
            }
        }
    }
    
    /**
        Fetches comments for a specific post from the server.
        
        - Parameters:
           - postId: The ID of the post for which comments are being fetched.
           - completion: A closure returning a `Result` type containing either a list of comments or a `NetworkError`.
        */
       func getComments(postId: Int, completion: @escaping (Result<[PostCommentsResponse.Comment], NetworkError>) -> Void) {
           let queryParameters: [String: String] = [
               "postId": "\(postId)"
           ]
           
           // Perform network request using NetworkingManager
           NetworkingManager.shared.request(
               endpoint: ApiConfig.Endpoints.getPostComments,
               method: "GET",
               queryParameters: queryParameters
           ) { (result: Result<PostCommentsResponse, NetworkError>) in
               switch result {
               case .success(let postCommentsResponse):
                   // Log the fetched comments
                   DDLogInfo("Fetched comments for post ID \(postId): \(postCommentsResponse.comments)")
                   
                   // Return the comments via the completion handler
                   completion(.success(postCommentsResponse.comments))
                   
               case .failure(let error):
                   // Log error details
                   DDLogError("Failed to fetch comments for post ID \(postId): \(error)")
                   
                   // Return the error via the completion handler
                   completion(.failure(error))
               }
           }
       }
    
    func addComment(commentRequest: CommentRequestModel, completion: @escaping (Result<CommentRest, NetworkError>) -> Void) {
          // Convert `CommentRequestModel` to a dictionary for the request body
          let parameters: [String: Any] = [
              "postId": commentRequest.postId,
              "userId": commentRequest.userId,
              "commentStr": commentRequest.commentStr
          ]
          
          // Perform the network request using NetworkingManager
          NetworkingManager.shared.request(
              endpoint: ApiConfig.Endpoints.addComment,
              method: "POST",
              parameters: parameters  // Pass the comment data as the request body
          ) { (result: Result<CommentRest, NetworkError>) in
              switch result {
              case .success(let commentResponse):
                  // Log success and return the comment via completion handler
                  DDLogInfo("Successfully added comment with ID \(commentResponse.commentId ?? 0) for post ID \(commentResponse.postId ?? 0)")
                  completion(.success(commentResponse))
                  
              case .failure(let error):
                  // Log the error and return it via completion handler
                  DDLogError("Failed to add comment: \(error)")
                  completion(.failure(error))
              }
          }
      }
    
  
    // Like a post
    func likePost(likeRequest: LikeRequestModel, completion: @escaping (Result<UserLikesDto.UserLike, NetworkError>) -> Void) {
        // Convert LikeRequestModel to dictionary
        let parameters: [String: Any] = [
            "postId": likeRequest.postId,
            "userId": likeRequest.userId
        ]
        
        // Perform network request to like the post
        NetworkingManager.shared.request(
            endpoint: ApiConfig.Endpoints.like,
            method: "POST",
            parameters: parameters  // Passing parameters as dictionary
        ) { (result: Result<UserLikesDto.UserLike, NetworkError>) in
            switch result {
            case .success(let userLike):
                // Handle the successful response here if needed
                DDLogInfo("Successfully liked post with likeId \(userLike.likeId)")
                completion(.success(userLike))
                
            case .failure(let error):
                // Handle the error here
                DDLogError("Failed to like the post: \(error)")
                completion(.failure(error))
            }
        }
    }



    // Unlike a post (Assuming this would require likeId and userId)
    func unlikePost(likeId: Int, userId: Int, completion: @escaping (Result<UnlikeRest, NetworkError>) -> Void) {
        let queryParameters: [String: String] = [
            "likeId": "\(likeId)",
            "userId": "\(userId)"
        ]
        
        NetworkingManager.shared.request(
            endpoint: ApiConfig.Endpoints.unlike,
            method: "DELETE",
            queryParameters: queryParameters
        ) { (result: Result<UnlikeRest, NetworkError>) in
            completion(result)
        }
    }

    // Get likes for a post
    func getLikesForPost(postId: Int, completion: @escaping (Result<[UserLikesDto.UserLike], NetworkError>) -> Void) {
        let queryParameters: [String: String] = [
            "postId": "\(postId)"
        ]
        
        NetworkingManager.shared.request(
            endpoint: ApiConfig.Endpoints.getPostLikes,
            method: "GET",
            queryParameters: queryParameters
        ) { (result: Result<UserLikesDto, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.postLikes))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Report Post
    func reportPost(postId: Int, completion: @escaping (Result<Int, NetworkError>) -> Void) {
        let queryParameters: [String: String] = ["postId": "\(postId)"]

        NetworkingManager.shared.request(
            endpoint: "api/post/report",
            method: "PUT",
            queryParameters: queryParameters
        ) { (result: Result<Int, NetworkError>) in
            switch result {
            case .success(let reportStatus):
                DDLogInfo("Post \(postId) reported successfully. Status Code: \(reportStatus)")
                completion(.success(reportStatus))
            case .failure(let error):
                DDLogError("Failed to report post \(postId): \(error)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Delete Post
    func deletePost(postId: Int, completion: @escaping (Result<Int, NetworkError>) -> Void) {
        let queryParameters: [String: String] = ["postId": "\(postId)"]

        NetworkingManager.shared.request(
            endpoint: "api/post",
            method: "DELETE",
            queryParameters: queryParameters
        ) { (result: Result<Int, NetworkError>) in
            switch result {
            case .success(let deleteStatus):
                DDLogInfo("Post \(postId) deleted successfully. Status Code: \(deleteStatus)")
                completion(.success(deleteStatus))
            case .failure(let error):
                DDLogError("Failed to delete post \(postId): \(error)")
                completion(.failure(error))
            }
        }
    }






    // Clear all posts from Core Data
    func clearAllData() {
        CoreDataManager.shared.deleteAllPosts()
    }
}
