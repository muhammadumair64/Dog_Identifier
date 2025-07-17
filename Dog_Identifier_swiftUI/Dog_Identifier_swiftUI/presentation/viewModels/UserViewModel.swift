import Foundation
import FirebaseAuth
import Combine
 
import CocoaLumberjack
import SwiftUI

class UserViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var isUserCreated: Bool = false
    @Published var currentUser: UserResponse? = nil
    @Published  var selectedTab: Int = 0
    private var cancellables = Set<AnyCancellable>()
    
    @Published var followers: [FollowerRest.Follower] = []
    @Published var following: [FollowingRest.Following] = []
   
    private let postRepository = PostRepository()
    @Published var isReportSuccess: Bool = false

    func createUser(user: myUser, completion: @escaping (Result<UserResponse, NetworkError>) -> Void) {
        isLoading = true
        errorMessage = ""
        isUserCreated = false
        var hasCompleted = false

        UserRepository.shared.createUser(user: user) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard !hasCompleted else {
                    DDLogWarn("ViewModel: Duplicate result ignored")
                    return
                }
                hasCompleted = true

                self.isLoading = false
                switch result {
                case .success(let createdUser):
                    self.isUserCreated = true
                    DDLogInfo("User created successfully: \(createdUser)")
                    UserDefaultManager.shared.set(createdUser.userId, forKey: UserDefaultManager.Key.currentUser)
                    completion(.success(createdUser))
                case .failure(let error):
                    self.errorMessage = self.handleError(error)
                    DDLogError("Error creating user: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }



    func getUserByUid(uid: String, completion: @escaping () -> Void) {
        isLoading = true
        errorMessage = ""
        currentUser = nil
        
        UserRepository.shared.getUserByUid(uid: uid) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    CoreDataManager.shared.saveUser(user: user)
                    self?.getFollowers(userId: String(user.userId))
                    self?.getFollowing(userId: String(user.userId))
                    print("Current user fetched successfully: \(user)")
                    UserDefaultManager.shared.set(user.userId, forKey: UserDefaultManager.Key.currentUser)
                case .failure(let error):
                    self?.errorMessage = self?.handleError(error) ?? "Unknown error"
                    print("Error fetching current user: \(error.localizedDescription)")
                }
                // Notify when data is fetched or error occurs
                completion()
            }
        }
    }

    func fetchUser(userId: Int) {
        if let myUser = CoreDataManager.shared.fetchUser(by: userId) {
            let userResponse = UserResponse(
                userId: Int(myUser.userId),
                uid: myUser.uid ?? "",
                name: myUser.name ?? "",
                email: myUser.email ?? "",
                number: myUser.number ?? "",
                notificationToken: myUser.notificationToken ?? "",
                imageUrl: myUser.imageUrl ?? "",
                address: myUser.address ?? "",
                city: myUser.city,
                country: myUser.country,
                bio: myUser.bio,
                createdAt: 0.0,
                lat: myUser.lat,
                reported: false
            )
            currentUser = userResponse
            getFollowers(userId: String(userId))
            getFollowing(userId: String(userId))
        } else {
            var uid = Auth.auth().currentUser?.uid ?? ""
            if uid != "" {
                getUserByUid(uid: uid) {}
            } else {
                currentUser = nil
            }
        }
    }

    // Fetch Followers
    func getFollowers(userId: String) {
        isLoading = true
        errorMessage = ""
       

        UserRepository.shared.getFollowers(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let followerRest):
                    self?.followers = followerRest.followers
                    print("Followers fetched successfully: \(followerRest)")
                case .failure(let error):
                    self?.errorMessage = self?.handleError(error) ?? "Unknown error"
                    print("Error fetching followers: \(error.localizedDescription)")
                }
            }
        }
    }

    // Fetch Following
    func getFollowing(userId: String) {
        isLoading = true
        errorMessage = ""

        UserRepository.shared.getFollowing(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let followingRest):
                    self?.following = followingRest.following
                    print("Following fetched successfully: \(followingRest)")
                case .failure(let error):
                    self?.errorMessage = self?.handleError(error) ?? "Unknown error"
                    print("Error fetching following: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Follow User
    func followUser(followerUserId: String, followedUserId: String) {
        isLoading = true
        errorMessage = ""
        DDLogDebug("MY FOLLOW REQUESTS followerUSerId=\(followerUserId) === followedUserId= \(followedUserId)")

        UserRepository.shared.follow(followerUserId: followerUserId, followedUserId: followedUserId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    print("Followed successfully: \(response)")
                    self?.getFollowing(userId: followerUserId)
                case .failure(let error):
                    self?.errorMessage = error.description
                    print("Error following user: \(error.description)")
                }
            }
        }
    }

    // MARK: - Unfollow User
    func unfollowUser(followerUserId: String, followedUserId: String ) {
        isLoading = true
        errorMessage = ""
        DDLogDebug("MY UNFOLLOW REQUESTS followerUSerId=\(followerUserId) === followedUserId= \(followedUserId)")

        UserRepository.shared.unfollow(followerUserId: followerUserId, followedUserId: followedUserId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    print("Unfollowed successfully: \(response)")
                    self?.getFollowing(userId: followerUserId)
                case .failure(let error):
                    self?.errorMessage = error.description
                    print("Error unfollowing user: \(error.description)")
                }
            }
        }
    }
    
    // MARK: - Report User
    func reportUser(userId: Int) {
        isLoading = true
        UserRepository.shared.reportUser(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    self?.isReportSuccess =  true
                    DDLogInfo("User \(userId) reported successfully")
                case .failure(let error):
                    DDLogError("Failed to report user \(userId): \(error.localizedDescription)")
                    self?.isReportSuccess =  true
                }
            }
        }
    }
    
    
    func logoutUser()
    {
        currentUser = nil
        UserDefaultManager.shared.remove(forKey: UserDefaultManager.Key.currentUser)
        CoreDataManager.shared.deleteAllUserPosts()
        CoreDataManager.shared.deleteAllUsers()

    }
    // Error handling function
    private func handleError(_ error: NetworkError) -> String {
        print("Handling error: \(error)")
        switch error {
        case .badURL:
            return "Invalid URL. Please check the endpoint."
        case .decodingError(let error):
            return "Failed to parse response. Error: \(error.localizedDescription)"
        case .serverError:
            return "Server error. Please try later."
        case .timeoutError:
            return "The request timed out. Please try again."
        case .unknown(let error):
            return "An unknown error occurred. \(error.localizedDescription)"
        }
    }
}
