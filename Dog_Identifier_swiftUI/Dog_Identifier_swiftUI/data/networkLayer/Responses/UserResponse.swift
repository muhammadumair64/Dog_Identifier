import Foundation

struct UserResponse: Codable {
    let userId: Int
    let uid: String
    let name: String
    let email: String
    let number: String
    let notificationToken: String
    let imageUrl: String
    let address: String
    let city: String?
    let country: String?
    let bio: String?
    let createdAt: Double
    let lat: Double
    let reported: Bool
}
