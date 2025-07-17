struct myUser: Codable {
    var userId: Int
    var uid: String
    var name: String
    var email: String
    var number: String
    var notificationToken: String
    var imageUrl: String?
    var address: String
    var city: String?  // Make this optional
    var country: String?  // Make this optional
    var bio: String
    var lat: Double
    var lng: Double

    // Initializer
    init(
        userId: Int = 0,
        uid: String = "",
        name: String = "",
        email: String = "",
        number: String = "",
        notificationToken: String = "",
        imageUrl: String? = "",
        address: String = "",
        city: String? = "",  // Make this optional
        country: String? = "",  // Make this optional
        bio: String = "",
        lat: Double = 0.0,
        lng: Double = 0.0
    ) {
        self.userId = userId
        self.uid = uid
        self.name = name
        self.email = email
        self.number = number
        self.notificationToken = notificationToken
        self.imageUrl = imageUrl
        self.address = address
        self.city = city
        self.country = country
        self.bio = bio
        self.lat = lat
        self.lng = lng
    }
}
