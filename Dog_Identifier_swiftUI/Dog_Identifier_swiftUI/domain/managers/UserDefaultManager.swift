//
//  UserDefaultManager.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 07/01/2025.
//


import Foundation

final class UserDefaultManager {
    static let shared = UserDefaultManager()
    
    private init() {}
    
    // MARK: - Keys
    enum Key: String {
        case sequenceNum
        case notificationToken
        case userPreferences
        case currentUser
        case secondLaunch
        case PRICE
        case isPremiumUser
        case freeScans
    }
    
    // MARK: - Generic Setter
    func set<T>(_ value: T?, forKey key: Key) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Generic Getter
    func get<T>(forKey key: Key) -> T? {
        return UserDefaults.standard.object(forKey: key.rawValue) as? T
    }
    
    // MARK: - Codable Support
    func setCodable<T: Codable>(_ value: T?, forKey key: Key) {
        let encoder = JSONEncoder()
        guard let value = value, let data = try? encoder.encode(value) else {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
            return
        }
        UserDefaults.standard.set(data, forKey: key.rawValue)
    }
    
    func getCodable<T: Codable>(forKey key: Key, type: T.Type) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
    // MARK: - Remove Key
    func remove(forKey key: Key) {
        UserDefaults.standard.removeObject(forKey: key.rawValue)
    }
    
    // MARK: - Clear All
    func clearAll() {
        for key in Key.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}

// Extend to make Key enumerable for bulk operations
extension UserDefaultManager.Key: CaseIterable {}


// MARK: -Usage Example
/*
 PreferenceManager.shared.set(42, forKey: .sequenceNum)
 let sequenceNum: Int? = PreferenceManager.shared.get(forKey: .sequenceNum)

 // Storing and retrieving custom Codable objects
 struct User: Codable {
     var id: Int
     var name: String
 }

 let user = User(id: 1, name: "John Doe")
 PreferenceManager.shared.setCodable(user, forKey: .userPreferences)

 if let retrievedUser = PreferenceManager.shared.getCodable(forKey: .userPreferences, type: User.self) {
     print(retrievedUser.name) // Output: John Doe
 }

 */


