import Foundation
import CocoaLumberjack

class UserRepository {
    static let shared = UserRepository()

    private init() {}

    func createUser(user: myUser, completion: @escaping (Result<UserResponse, NetworkError>) -> Void) {
        let parameters: [String: Any] = [
            "userId": user.userId,
            "uid": user.uid,
            "name": user.name,
            "email": user.email,
            "number": user.number,
            "notificationToken": user.notificationToken,
            "imageUrl": user.imageUrl ?? "",
            "address": user.address,
            "city": user.city,
            "country": user.country,
            "bio": user.bio,
            "lat": user.lat,
            "lng": user.lng
        ]
        
        NetworkingManager.shared.request(endpoint: ApiConfig.Endpoints.createUser, method: "POST", parameters: parameters) { (result: Result<UserResponse, NetworkError>) in
            completion(result)
        }
    }
    
    // New method to fetch the current user by UID
    func getUserByUid(uid: String, completion: @escaping (Result<UserResponse, NetworkError>) -> Void) {
        let queryParams: [String: String] = [
            "uid": uid
        ]
        
        NetworkingManager.shared.request(endpoint: ApiConfig.Endpoints.getUserByUid, method: "GET", queryParameters: queryParams) { (result: Result<UserResponse, NetworkError>) in
            completion(result)
        }
    }
    
    // Fetch Followers
    func getFollowers(userId: String, completion: @escaping (Result<FollowerRest, NetworkError>) -> Void) {
        NetworkingManager.shared.request(
            endpoint: ApiConfig.Endpoints.getFollowers,
            method: "GET",
            queryParameters: ["userId": userId]
        ) { (result: Result<FollowerRest, NetworkError>) in
            completion(result)
        }
    }

    // Fetch Following
    func getFollowing(userId: String, completion: @escaping (Result<FollowingRest, NetworkError>) -> Void) {
        NetworkingManager.shared.request(
            endpoint: ApiConfig.Endpoints.getFollowing,
            method: "GET",
            queryParameters: ["userId": userId]
        ) { (result: Result<FollowingRest, NetworkError>) in
            completion(result)
        }
    }
    
    
    func unfollow(
        followerUserId: String,
        followedUserId: String,
           completion: @escaping (Result<UnFollowRest, NetworkError>) -> Void
       ) {
           let parameters: [String: String] = [
               "followerUserId": followerUserId,
               "followedUserId": followedUserId
           ]
           
           NetworkingManager.shared.request(
               endpoint: "api/unfollow",
               method: "POST",
               queryParameters: parameters
           ) { (result: Result<UnFollowRest, NetworkError>) in
               completion(result)
           }
       }
    
    func follow(
        followerUserId: String,
        followedUserId: String,
        completion: @escaping (Result<AddFollowRest, NetworkError>) -> Void
    ) {
        let parameters: [String: String] = [
            "followerUserId": followerUserId,
            "followedUserId": followedUserId
        ]
        
        NetworkingManager.shared.request(
            endpoint: "api/follower",
            method: "POST",
            queryParameters: parameters
        ) { (result: Result<AddFollowRest, NetworkError>) in
            completion(result)
        }
    }
    // MARK: - Report User
      func reportUser(userId: Int, completion: @escaping (Result<Void, NetworkError>) -> Void) {
          let queryParameters: [String: String] = ["userId": "\(userId)"]

          NetworkingManager.shared.request(
              endpoint: "api/user/report",
              method: "PUT",
              queryParameters: queryParameters
          ) { (result: Result<Data, NetworkError>) in
              switch result {
              case .success:
                  DDLogInfo("User \(userId) reported successfully")
                  completion(.success(())) // Void success
              case .failure(let error):
                  DDLogError("Failed to report user \(userId): \(error)")
                  completion(.failure(error))
              }
          }
      }
 
    
}
