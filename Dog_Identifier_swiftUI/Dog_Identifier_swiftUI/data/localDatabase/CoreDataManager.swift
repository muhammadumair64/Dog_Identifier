//
//  CoreDataManager.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 06/01/2025.
//


import UIKit
import CoreData
import CocoaLumberjack

class CoreDataManager {
    static let shared = CoreDataManager()
     let context = PersistenceController.shared.context

    // MARK: - Save User
    func saveUser(user: UserResponse) {
        let User = User(context: context)
        User.userId = Int32(user.userId)
        User.uid = user.uid
        User.name = user.name
        User.email = user.email
        User.number = user.number
        User.notificationToken = user.notificationToken
        User.imageUrl = user.imageUrl
        User.address = user.address
        User.city = user.city
        User.country = user.country
        User.bio = user.bio
        User.lat = user.lat
        User.lng = 0.0
        
        saveContext() // Save the context after inserting the user data
        DDLogDebug("User saved: \(user.name)") // Log the user save
    }

    
    // MARK: - Fetch User by User ID
    func fetchUser(by userId: Int) -> User? {
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %d", userId) // Use userId as the predicate
        fetchRequest.fetchLimit = 1 // Fetch only one user

        do {
            return try context.fetch(fetchRequest).first // Return the first user (if any)
        } catch {
            DDLogError("Failed to fetch user with User ID \(userId): \(error.localizedDescription)") // Log any errors
            return nil
        }
    }

    // MARK: - Update Existing User
    func updateUser(_ existingUser: User, with user: User) {
        existingUser.name = user.name
        existingUser.email = user.email
        existingUser.number = user.number
        existingUser.notificationToken = user.notificationToken
        existingUser.imageUrl = user.imageUrl
        existingUser.address = user.address
        existingUser.city = user.city
        existingUser.country = user.country
        existingUser.bio = user.bio
        existingUser.lat = user.lat
        existingUser.lng = user.lng

        saveContext() // Save the context after updating the user data
        DDLogDebug("User updated: \(user.name ?? "")") // Log the user update
    }

    
    // MARK: - Delete User
    func deleteUser(_ user: User) {
        context.delete(user)
        saveContext() // Save after deleting the user
        DDLogDebug("User deleted") // Log the user deletion
    }
    // MARK: - Delete All Users
    func deleteAllUsers() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save() // Save the context to apply changes
            DDLogInfo("Successfully deleted all users from the database.")
        } catch {
            DDLogError("Failed to delete all users: \(error.localizedDescription)")
        }
    }

    // MARK: - Save ScanCollection
    func saveScan(id: UUID = UUID(), name: String, description: String?, image: UIImage) {
        let scan = ScanCollection(context: context)
        scan.id = id
        scan.name = name
        scan.insectDesciption = description
        scan.image = image.fixOrientation().pngData()

        saveContext()
    }

    // MARK: - Fetch All Scans
    func fetchAllScans() -> [ScanCollection] {
        let fetchRequest: NSFetchRequest<ScanCollection> = ScanCollection.fetchRequest()

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch scans: \(error)")
            return []
        }
    }

    // MARK: - Fetch by ID
    func fetchScan(by id: UUID) -> ScanCollection? {
        let fetchRequest: NSFetchRequest<ScanCollection> = ScanCollection.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch scan by ID: \(error)")
            return nil
        }
    }

    // MARK: - Delete Scan
    func deleteScan(_ scan: ScanCollection) {
        context.delete(scan)
        saveContext()
    }

    
    // MARK: - Save Posts
    func savePosts(posts: [Post], page: Int) {
        let backgroundContext = PersistenceController.shared.newBackgroundContext()
        backgroundContext.perform {
            for post in posts {
                let entity = PostEntity(context: backgroundContext)
                entity.postId = Int32(post.postID)
                entity.location = post.location
                entity.createdAt = Int64(post.createdAt)
                entity.watcherCount = Int32(post.watcherCount)
                entity.userName = post.userName
                entity.descriptionText = post.description
                entity.userId = Int32(post.userID)
                entity.imageUrl = post.imageURL
                entity.title = post.title
                entity.userImage = post.userImage
                entity.userBio = post.userBio
                entity.likeCount = Int32(post.likeCount)
                entity.commentCount = Int32(post.commentCount)
                entity.category = post.category
                entity.pageNumber = Int32(page)
                entity.lastFetched = Date()
            }

            do {
                try backgroundContext.save()
                DDLogDebug("Saved Posts For page \(page)")
                
                // Post a notification after saving
                NotificationCenter.default.post(name: .newPostsSaved, object: nil)
            } catch {
                DDLogError("Failed to save posts: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Save User Posts
    func saveUserPosts(posts: [Post], completion: @escaping (Bool) -> Void) {
        let backgroundContext = PersistenceController.shared.newBackgroundContext()
        backgroundContext.perform {
            for post in posts {
                let entity = UserPosts(context: backgroundContext)
                entity.postId = Int32(post.postID)
                entity.location = post.location
                entity.createdAt = Int64(post.createdAt)
                entity.watcherCount = Int32(post.watcherCount)
                entity.userName = post.userName
                entity.descriptionText = post.description
                entity.userId = Int32(post.userID)
                entity.imageUrl = post.imageURL
                entity.title = post.title
                entity.userImage = post.userImage
                entity.userBio = post.userBio
                entity.likeCount = Int32(post.likeCount)
                entity.commentCount = Int32(post.commentCount)
                entity.category = post.category
                entity.lastFetched = Date()

                DDLogDebug("USER POST IS SAVED: \(entity)")
            }

            do {
                try backgroundContext.save()
                // Post a notification after saving
                DDLogInfo("Successfully Saved user posts.")

                NotificationCenter.default.post(name: .newPostsSaved, object: nil)
                completion(true)
            } catch {
                DDLogError("Failed to save posts: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    
    // MARK: - Fetch User Posts
    func fetchUserPosts() -> [UserPosts] {
        let mainContext = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<UserPosts> = UserPosts.fetchRequest()
        
        do {
            // Perform fetch without sorting
            let userPosts = try mainContext.fetch(fetchRequest)
            DDLogInfo("Successfully fetched \(userPosts.count) user posts.")
            return userPosts
        } catch {
            DDLogError("Failed to fetch user posts: \(error.localizedDescription)")
            return []
        }
    }

    
    // MARK: - Delete All User Posts
    func deleteAllUserPosts() {
        let mainContext = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = UserPosts.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try mainContext.execute(batchDeleteRequest)
            try mainContext.save()
            DDLogInfo("Successfully deleted all user posts.")
        } catch {
            DDLogError("Failed to delete all user posts: \(error.localizedDescription)")
        }
    }


    // MARK: - Update Post
    func updatePost(postId: Int, likeCount: Int, commentCount: Int) {
        let fetchRequest: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "postId == %d", postId)
        
        do {
            // Fetch the post with the given postId
            let posts = try context.fetch(fetchRequest)
            print("POst:- ", posts)
            
            if let existingPost = posts.first {
                print(existingPost)
                // Update the existing post without deleting it to retain the index
                existingPost.likeCount = Int32(likeCount)
                existingPost.commentCount = Int32(commentCount)
                DDLogDebug("Updated existing post \(postId) with likeCount: \(likeCount), commentCount: \(commentCount)")
            } else {
                // If post does not exist, log an error or perform appropriate action
                DDLogWarn("Post \(postId) does not exist. No update performed.")
                return // Return early to avoid creating a duplicate
            }
            
            // Save changes to the context
            try context.save()
            DDLogInfo("Successfully updated post \(postId)")
            
            let oldData = fetchPosts(page: 1, limit: 20)
            print(oldData.count)
        } catch {
            DDLogError("Failed to update post \(postId): \(error.localizedDescription)")
        }
    }


       // MARK: - Fetch Posts for a Specific Page
       func fetchPosts(page: Int, limit: Int) -> [PostEntity] {
           DDLogDebug("Fetching Post For page \(page)")
           let fetchRequest: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
           fetchRequest.predicate = NSPredicate(format: "pageNumber == %d", page)
           fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
           fetchRequest.fetchLimit = limit

           do {
               return try context.fetch(fetchRequest)
           } catch {
               print("Failed to fetch posts: \(error.localizedDescription)")
               return []
           }
       }


       // MARK: - Fetch All Posts with Pagination
       func fetchAllPosts(limit: Int, offset: Int) -> [PostEntity] {
           let fetchRequest: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
           fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
           fetchRequest.fetchLimit = limit
           fetchRequest.fetchOffset = offset

           do {
               return try context.fetch(fetchRequest)
           } catch {
               print("Failed to fetch all posts: \(error.localizedDescription)")
               return []
           }
       }

       // MARK: - Delete All Posts
       func deleteAllPosts() {
           let fetchRequest: NSFetchRequest<NSFetchRequestResult> = PostEntity.fetchRequest()
           let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

           do {
               try context.execute(deleteRequest)
               try context.save()
           } catch {
               print("Failed to delete all posts: \(error.localizedDescription)")
           }
       }

       // MARK: - Determine if Page 1 Needs Refresh
       func shouldRefreshPage1() -> Bool {
           let fetchRequest: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
           fetchRequest.predicate = NSPredicate(format: "pageNumber == %d", 1)
           fetchRequest.fetchLimit = 1
           fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastFetched", ascending: false)]

           do {
               if let lastFetched = try context.fetch(fetchRequest).first?.lastFetched {
                   return abs(lastFetched.timeIntervalSinceNow) > 300 // 5 minutes
               }
               return true
           } catch {
               print("Failed to check last fetched timestamp: \(error.localizedDescription)")
               return true
           }
       }

    // MARK: - Save Context
    func saveContext() {
            do {
                try context.save()
            } catch {
                DDLogError("Failed to save context: \(error.localizedDescription)")
            }
    }

}
