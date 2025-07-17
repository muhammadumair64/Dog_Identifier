import CocoaLumberjack
import Combine
import CoreData
import Foundation
import SwiftUI

/// ViewModel responsible for managing and fetching posts for the UI.
class PostViewModel: NSObject, ObservableObject {

    // MARK: - Properties

    /// Repository to fetch posts from the server.
    private let postRepository = PostRepository()

    /// Core Data manager to interact with the local data store.
    private let coreDataManager: CoreDataManager

    /// Published array to hold posts for UI display.
    @Published var posts: [PostEntity] = []

    /// Published property to indicate loading state for UI.
    @Published var isLoading: Bool = false

    /// Current page index for pagination.
    private var currentPage: Int = 1

    /// Flag to indicate if more pages are available for pagination.
    private var hasMorePages: Bool = true

    /// Number of posts to fetch per page.
    private let limitPerPage: Int = 20

    @Published var lastContentOffset: CGFloat = 0

    /// Set of cancellables to manage Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()

    /// FetchedResultsController for Core Data to monitor changes in the post entities.
    private var frc: NSFetchedResultsController<PostEntity>!

    @Published var isImageUploaded = false
    @Published var UploadedImageURL: String = ""
    @Published var selectedPost: PostEntity? = nil
    @Published var selectedIndex: Int?  // Store the selected post's index

    /// Published array to hold the comments of the selected post.
    @Published var selectedPostComments: [PostCommentsResponse.Comment] = []
    @Published var likes: [UserLikesDto.UserLike] = []
    @Published var isPostUploaded = false
    @Published var userPosts: [UserPosts] = []
    @Published var totalLikes: Int = 0
    @Published var selectedUserPost: UserPosts? = nil
    @Published var selectedCollection: ScanCollection? = nil
    
    @Published var imageForPost: UIImage? = nil
    @Published var titleForPost: String? = ""
    @Published var descriptionForPost: String? = ""

    @Published var isReportSuccess: Bool = false
    
    
    
    // MARK: - Initialization

    /**
     Initializes the ViewModel, sets up Core Data and subscribes to relevant notifications.

     - Parameter coreDataManager: The CoreDataManager instance to interact with the local database.
     */
    init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
        super.init()
        self.setupFetchedResultsController()

        // Observe the "newPostsSaved" notification to trigger a refresh when new data is added.
        NotificationCenter.default.addObserver(
            self, selector: #selector(refreshPostsFromNotification),
            name: .newPostsSaved, object: nil)
    }

    deinit {
        // Remove observer when the ViewModel is deinitialized to prevent memory leaks.
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Refresh Posts from Notification

    /**
     Refreshes the posts when a "newPostsSaved" notification is received.
     */
    @objc private func refreshPostsFromNotification() {
        loadPosts()  // Reload posts to reflect the latest data.
    }

    // MARK: - Setup FetchedResultsController

    /**
     Configures and initializes the `NSFetchedResultsController` for Core Data.

     The fetch request is configured to sort posts by `createdAt` in descending order.
     */
    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        fetchRequest.fetchLimit = limitPerPage

        frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: coreDataManager.context,
            sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self

        do {
            try frc.performFetch()  // Fetch initial posts from Core Data
            posts = frc.fetchedObjects ?? []  // Assign fetched posts to the `posts` array
        } catch {
            DDLogError("Failed to fetch posts: \(error.localizedDescription)")  // Log error if fetch fails
        }
    }

    // MARK: - Load Posts

    /**
     Loads posts either from Core Data or from the server.

     If Core Data has data for the current page, it is loaded and displayed.
     Otherwise, it triggers a fetch from the server.
     */
    func loadPosts() {
        DispatchQueue.main.async {
            self.isLoading = true
        }

        // Attempt to fetch posts from Core Data for the current page.
        let coreDataPosts = coreDataManager.fetchPosts(
            page: currentPage, limit: limitPerPage)

        if !coreDataPosts.isEmpty {
            // If Core Data returns posts, append them to the `posts` array.
            appendPosts(coreDataPosts)
            DispatchQueue.main.async {
                self.isLoading = false
            }

        } else {
            DDLogDebug("Before fetching posts from server...\(currentPage)")  // Log for debugging before fetching from server
            // If no data is found in Core Data, fetch posts from the server.
            fetchPostsFromServer(page: currentPage)
        }
    }
    

    // MARK: - Fetch Posts from Server

    /**
     Fetches posts from the server.

     The fetched posts are then appended to the `posts` array, and the current page index is incremented.

     - Parameter page: The current page number to fetch.
     */
    private func fetchPostsFromServer(page: Int) {
        postRepository.getPosts(page: page, size: limitPerPage) {
            [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let fetchedPosts):
                    // If posts are fetched successfully, append them to the posts array.
                    if fetchedPosts.isEmpty {
                        self.hasMorePages = false  // No more pages available
                    } else {
                        self.appendPosts(fetchedPosts)  // Append newly fetched posts
                    }
                case .failure(let error):
                    DDLogError(
                        "Failed to fetch from server: \(error.localizedDescription)"
                    )  // Log error if fetching fails
                }
                self.isLoading = false  // Set loading state to false after the fetch is complete.
            }
        }
    }
    
    // MARK: - Create Posts
    func createNewPost(
        userId: Int ,uid: String, title: String, description: String, imageUrl: String,
        location: String, lat: Float, lng: Float, category: String?
    )
    {
        let postModel = CreatePostModel(
            uid: uid,
            title: title,
            description: description,
            imageUrl: imageUrl,
            location: location,
            lat: lat,
            lng: lng,
            category: category
        )

        postRepository.createPost(userId: userId, postModel: postModel) {
            [weak self] result in
            DispatchQueue.main.async {
                guard self != nil else { return }
                switch result {
                case .success(let responsePostModel):
                    // Handle the success, e.g., add the new post to the local posts array or UI
                    DDLogInfo("Post created successfully: \(responsePostModel)")
                    self?.refreshUserPosts(userId: userId)
                    self?.isLoading = false
                    self?.isPostUploaded = true
                case .failure(let error):
                    // Handle the error, show a message to the user
                    DDLogError(
                        "Error creating post: \(error.localizedDescription)")
                    self?.isLoading = false
                }
            }
        }
    }

    func uploadImage(
        image: UIImage, userId: Int ,uid: String , title: String, description: String,
        location: String, lat: Float, lng: Float, category: String?
    )
    {
        isLoading = true
        postRepository.uploadImage(image: image) { [weak self] result in
            DispatchQueue.main.async {
             
                switch result {
                case .success(let success):
                    self?.isImageUploaded = true
                    self?.UploadedImageURL = success
                    self?.createNewPost(
                        userId: userId,
                        uid: uid,
                        title: title,
                        description: description,
                        imageUrl: success,
                        location: location,
                        lat: Float(lat),
                        lng: Float(lng),
                        category: category
                    )
                    DDLogInfo("Image uploaded successfully")

                case .failure(let error):
                    self?.isLoading = false
                    DDLogError(
                        "Failed to upload image: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Append Posts to Display

    /**
     Appends newly fetched posts to the existing `posts` array on the main thread.

     - Parameter newPosts: The new posts to append to the `posts` array.
     */
    private func appendPosts(_ newPosts: [PostEntity]) {
        DispatchQueue.main.async {
            // Append new posts to the array
            self.posts.append(contentsOf: newPosts)

            // Remove duplicates from self.posts based on postId
            self.posts = self.posts.filter { post in
                // Keep only the first instance of each postId
                return self.posts.firstIndex(where: { $0.postId == post.postId }
                ) == self.posts.firstIndex(of: post)
            }

            // Increment the page index for the next fetch
            self.currentPage += 1

            // Log the count of posts loaded
            DDLogDebug("MY POSTS LOADED \(self.posts.count)")

        }
    }

    // MARK: - Load Next Page on Scroll

    /**
     Loads the next page of posts if the user has scrolled to the last post.

     - Parameter currentItem: The last visible post item in the current view.
     */
    func loadNextPageIfNeeded(currentItem: PostEntity?) {
        guard let currentItem = currentItem else { return }
        if posts.last == currentItem {
            DDLogDebug("Before loading")  // Log for debugging before loading next page
            loadPosts()  // Load next page of posts
        }
    }
    // MARK: - Refresh All Posts

    /**
     Refreshes the entire posts list by resetting pagination and re-fetching all posts.
     */
    func refreshPosts() {
        coreDataManager.deleteAllPosts()
        DispatchQueue.main.async {
            self.posts.removeAll()
        }

         // Step 2: Reset the page index to the first page
        currentPage = 1

        // Step 3: Reset the "has more pages" flag
        hasMorePages = true

        // Step 4: Reload posts from Core Data or the server (async)
        loadPosts()
    }

    func refreshUserPosts(userId:Int){
        coreDataManager.deleteAllPosts()
        userPosts.removeAll()
        fetchUserPostsFromServer(userId: userId)
    }
    
    // MARK: - Update Post
    func updatePost(postId: Int, likeCount: Int, commentCount: Int) {
        DDLogDebug(
            "Updating post in ViewModel with postId: \(postId), likeCount: \(likeCount), commentCount: \(commentCount)"
        )

        CoreDataManager.shared.updatePost(
            postId: postId, likeCount: likeCount, commentCount: commentCount)

        posts.removeAll()

        // loadPosts()
    }

    
    // MARK: - update watcher Count
    func addWatcherCount(postId: Int) {
        isLoading = true
        postRepository.addWatcherCount(postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let result):
                    DDLogInfo("Post \(postId) Watcher Inscrease successfully \(result)")
                case .failure(let error):
                    DDLogError(
                        "Failed to like post \(postId): \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    // MARK: - Like Post
    // Like a post
    func likePost(
        postId: Int, userId: Int, completion: @escaping (Bool, Int?) -> Void
    ) {
        let likeRequest = LikeRequestModel(postId: postId, userId: userId)
        isLoading = true
        postRepository.likePost(likeRequest: likeRequest) {
            [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let like):
                    self?.likes.append(like)
                    completion(true, like.likeId)
                    DDLogInfo("Post \(postId) liked successfully")
                case .failure(let error):
                    DDLogError(
                        "Failed to like post \(postId): \(error.localizedDescription)"
                    )
                    completion(false, nil)
                }
            }
        }
    }
    
    // Unlike a post
    func unlikePost(
        likeId: Int, userId: Int, completion: @escaping (Bool) -> Void
    )
    {
        isLoading = true
        postRepository.unlikePost(likeId: likeId, userId: userId) {
            [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let result):
                    if result.unLikeSuccessful {
                        self?.likes.removeAll { $0.likeId == likeId }
                        completion(true)  // Pass success
                        DDLogInfo(
                            "Post with likeId \(likeId) unliked successfully")
                    } else {
                        completion(false)  // Pass failure due to unsuccessful unliking
                        DDLogWarn(
                            "Unliking post with likeId \(likeId) was not successful"
                        )
                    }
                case .failure(let error):
                    DDLogError(
                        "Failed to unlike post \(likeId): \(error.localizedDescription)"
                    )
                    completion(false)  // Pass failure
                }
            }
        }
    }
    
    
    // Updated getLikes with a completion handler
    func getLikes(postId: Int, completion: @escaping (Bool) -> Void) {
        likes.removeAll()
        isLoading = true
        postRepository.getLikesForPost(postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let likes):
                    self?.likes = likes
                    DDLogDebug("Likes fetched successfully for post \(postId)")
                    completion(true)  // Notify success
                case .failure(let error):
                    DDLogError(
                        "Failed to fetch likes for post \(postId): \(error.localizedDescription)"
                    )
                    completion(false)  // Notify failure
                }
            }
        }
    }
   

    // MARK: - Fetch Comments

    /**
         Fetches comments for a specific post and updates the `selectedPostComments`.

         - Parameters:
            - postId: The ID of the post for which comments are being fetched.
         */
    func fetchComments(for postId: Int) {
        postRepository.getComments(postId: postId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let comments):
                    // Log and update the `selectedPostComments`
                    DDLogInfo(
                        "Successfully fetched \(comments.count) comments for post ID \(postId)"
                    )
                    self.selectedPostComments.removeAll()
                    self.selectedPostComments = comments

                case .failure(let error):
                    // Log the error
                    DDLogError(
                        "Failed to fetch comments for post ID \(postId): \(error.localizedDescription)"
                    )
                    self.selectedPostComments = []  // Clear comments on error
                }

                self.isLoading = false  // Hide loading indicator
            }
        }
    }

    func addComment(postId: Int, userId: Int, str: String) {
        let commentRequest = CommentRequestModel(
            postId: postId, userId: userId, commentStr: str)
        isLoading = true

        postRepository.addComment(commentRequest: commentRequest) {
            [weak self] result in
            // This block is executed on a background thread, so you need to dispatch UI updates to the main thread
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let result):
                    self?.fetchComments(for: postId)
                    self?.selectedPost?.commentCount += 1
                    self?.updatePost(
                        postId: postId,
                        likeCount: Int(self?.selectedPost?.likeCount ?? 0),
                        commentCount: Int(self?.selectedPost?.commentCount ?? 0)
                    )
                    DDLogInfo("Added successfully \(result.commentStr ?? "")")

                case .failure(let error):
                    DDLogError(
                        "Failed to add comment \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Report Post
        func reportPost(postId: Int) {
            isLoading = true
            postRepository.reportPost(postId: postId) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let statusCode):
                        self?.isReportSuccess =  true
                        DDLogInfo("Post \(postId) reported successfully. Status Code: \(statusCode)")
                    case .failure(let error):
                        DDLogError("Failed to report post \(postId): \(error.localizedDescription)")
                    }
                }
            }
        }

        // MARK: - Delete Post
    func deletePost(postId: Int,userId:Int) {
            isLoading = true
            postRepository.deletePost(postId: postId) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    switch result {
                    case .success(let statusCode):
                        DDLogInfo("Post \(postId) deleted successfully. Status Code: \(statusCode)")
                        CoreDataManager.shared.deleteAllUserPosts()
                        self?.fetchUserPostsFromServer(userId: userId)
                        self?.isReportSuccess =  true
                    case .failure(let error):
                        DDLogError("Failed to delete post \(postId): \(error.localizedDescription)")
                    }
                }
            }
        }
    
    
    // MARK: - USER POSTS
    
    func fetchUserPosts(){
        let localUserPosts = CoreDataManager.shared.fetchUserPosts()
        DDLogDebug("USER POST IN PostViewModel \(localUserPosts)")
        self.appendUserPosts(localUserPosts: localUserPosts)
    }

    private func fetchUserPostsFromServer(userId:Int) {
        postRepository.getUserPosts(userId: userId) {
            [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let fetchedPosts):
                    DDLogDebug("Successfully fetch user posts \(fetchedPosts.count)")
                    self.appendUserPosts(localUserPosts: fetchedPosts)
                    
                case .failure(let error):
                    DDLogError(
                        "Failed to fetch from server: \(error.localizedDescription)"
                    )  // Log error if fetching fails
                }
                self.isLoading = false  // Set loading state to false after the fetch is complete.
            }
        }
    }
    
    func appendUserPosts(localUserPosts : [UserPosts]){
        if !localUserPosts.isEmpty {
                    userPosts.removeAll()
                    userPosts.append(contentsOf: localUserPosts)
                    
                    // Calculate total likes using a loop
                    var likeCountSum = 0
                    for post in userPosts {
                        likeCountSum += Int(post.likeCount)
                    }
                    totalLikes = likeCountSum
                    DDLogInfo("Total Likes: \(totalLikes)")
                } else {
                    // If no posts are fetched, reset totalLikes
                    totalLikes = 0
                    DDLogInfo("No user posts found. Total Likes reset to 0.")
                }
    }
    func clearCreatePostData(){
        imageForPost = nil
        titleForPost = ""
        descriptionForPost = ""
    }
}



/// Conforms to `NSFetchedResultsControllerDelegate` to handle changes in Core Data and update the posts array accordingly.
    extension PostViewModel: NSFetchedResultsControllerDelegate {

    /**
     Called when the content of the fetched results controller changes.

     This updates the `posts` array with the latest data from Core Data.

     - Parameter controller: The fetched results controller that triggered the change.
     */
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        DispatchQueue.main.async {
            self.posts = self.frc.fetchedObjects ?? []  // Update the posts array with new fetched objects
        }
    }
        
}
