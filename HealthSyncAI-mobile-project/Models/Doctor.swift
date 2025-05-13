import Foundation

struct Doctor: Codable, Identifiable {
    let id: Int
    let firstName: String
    let lastName: String
    let specialization: String?
    let qualifications: String?
    let email: String
    let isAvailable: Bool
    let yearsExperience: Int? // Allow for null
    let bio: String?
    let rating: Double? // Allow for null

    // For Identifiable in lists
    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let firstInitial = firstName.first.map { String($0) } ?? ""
        let lastInitial = lastName.first.map { String($0) } ?? ""
        return firstInitial + lastInitial
    }

    // CodingKeys to map snake_case JSON to camelCase Swift properties
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case specialization
        case qualifications
        case email
        case isAvailable = "is_available"
        case yearsExperience = "years_experience"
        case bio
        case rating
    }

    // Provide a default initializer if needed (e.g., for placeholders)
    init(id: Int = 0, firstName: String = "N/A", lastName: String = "", specialization: String? = nil, qualifications: String? = nil, email: String = "", isAvailable: Bool = false, yearsExperience: Int? = nil, bio: String? = nil, rating: Double? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.specialization = specialization
        self.qualifications = qualifications
        self.email = email
        self.isAvailable = isAvailable
        self.yearsExperience = yearsExperience
        self.bio = bio
        self.rating = rating
    }
}
