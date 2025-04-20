// HealthSyncAI-mobile-project/Models/RegistrationData.swift
import Foundation

// Base data common to both patient and doctor registration
// This struct is now mainly for organizing properties conceptually,
// the actual encoding/decoding happens in the Patient/Doctor structs.
struct BaseRegistrationData {
    var username: String
    var email: String
    var password: String
    var firstName: String
    var lastName: String
}

// Specific data for patient registration - NOW FLATTENED FOR ENCODING/DECODING
struct PatientRegistrationData: Codable {
    // Declare ALL fields directly
    var username: String
    var email: String
    var password: String // Only needed for encoding
    var firstName: String
    var lastName: String
    var dateOfBirth: String
    var gender: String // This will hold the backend-expected value ('male', etc.)
    var heightCm: Double
    var weightKg: Double
    var bloodType: String
    var allergies: String?
    var existingConditions: String?

    // CodingKeys for the FLAT structure expected/received by the API
    enum CodingKeys: String, CodingKey {
        case username, email, password // Top level
        case firstName = "first_name"    // Map to snake_case
        case lastName = "last_name"    // Map to snake_case
        case dateOfBirth = "date_of_birth"
        case gender
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case bloodType = "blood_type"
        case allergies
        case existingConditions = "existing_conditions"
    }

    // Custom encoder to create the flat structure
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password) // Include password for registration
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(gender, forKey: .gender) // Encode the correct backend value
        try container.encode(heightCm, forKey: .heightCm)
        try container.encode(weightKg, forKey: .weightKg)
        try container.encode(bloodType, forKey: .bloodType)
        try container.encodeIfPresent(allergies, forKey: .allergies)
        try container.encodeIfPresent(existingConditions, forKey: .existingConditions)
    }

    // Required initializer for Decodable conformance (even if not used for response)
    // This assumes you might decode this structure elsewhere, otherwise it can be simpler.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        password = "" // Password is not typically decoded from responses
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        dateOfBirth = try container.decode(String.self, forKey: .dateOfBirth)
        gender = try container.decode(String.self, forKey: .gender)
        heightCm = try container.decode(Double.self, forKey: .heightCm)
        weightKg = try container.decode(Double.self, forKey: .weightKg)
        bloodType = try container.decode(String.self, forKey: .bloodType)
        allergies = try container.decodeIfPresent(String.self, forKey: .allergies)
        existingConditions = try container.decodeIfPresent(String.self, forKey: .existingConditions)
    }

    // Add a memberwise initializer for easier creation in the ViewModel
     init(username: String, email: String, password: String, firstName: String, lastName: String, dateOfBirth: String, gender: String, heightCm: Double, weightKg: Double, bloodType: String, allergies: String? = nil, existingConditions: String? = nil) {
         self.username = username
         self.email = email
         self.password = password
         self.firstName = firstName
         self.lastName = lastName
         self.dateOfBirth = dateOfBirth
         self.gender = gender
         self.heightCm = heightCm
         self.weightKg = weightKg
         self.bloodType = bloodType
         self.allergies = allergies
         self.existingConditions = existingConditions
     }
}


// Specific data for doctor registration - NOW FLATTENED
struct DoctorRegistrationData: Codable {
    // Declare ALL fields directly
    var username: String
    var email: String
    var password: String // Only needed for encoding
    var firstName: String
    var lastName: String
    var role: String = "doctor"
    var specialization: String
    var qualifications: String
    var isAvailable: Bool

    // CodingKeys for the FLAT structure
    enum CodingKeys: String, CodingKey {
        case username, email, password, role, specialization, qualifications // Top level
        case firstName = "first_name" // Map to snake_case
        case lastName = "last_name"   // Map to snake_case
        case isAvailable = "is_available" // Map to snake_case
    }

    // Custom encoder for flat structure
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encode(role, forKey: .role)
        try container.encode(specialization, forKey: .specialization)
        try container.encode(qualifications, forKey: .qualifications)
        try container.encode(isAvailable, forKey: .isAvailable)
    }

    // Required initializer for Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        password = "" // Not decoded
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        role = try container.decode(String.self, forKey: .role)
        specialization = try container.decode(String.self, forKey: .specialization)
        qualifications = try container.decode(String.self, forKey: .qualifications)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
    }

    // Add a memberwise initializer
     init(username: String, email: String, password: String, firstName: String, lastName: String, specialization: String, qualifications: String, isAvailable: Bool) {
         self.username = username
         self.email = email
         self.password = password
         self.firstName = firstName
         self.lastName = lastName
         self.role = "doctor" // Ensure role is set
         self.specialization = specialization
         self.qualifications = qualifications
         self.isAvailable = isAvailable
     }
}

// Combined Enum - Encoding logic simplified as structs handle flatness now
enum RegistrationData {
    case patient(PatientRegistrationData)
    case doctor(DoctorRegistrationData)

    // Helper to get the encodable data
    func encodeToJson() throws -> Data {
        let encoder = JSONEncoder()
        // REMOVE keyEncodingStrategy here - it's handled by CodingKeys in structs now
        // encoder.keyEncodingStrategy = .convertToSnakeCase
         encoder.outputFormatting = .prettyPrinted // Optional for debugging

        switch self {
        case .patient(let data):
            return try encoder.encode(data) // Uses PatientRegistrationData's encoder
        case .doctor(let data):
            return try encoder.encode(data) // Uses DoctorRegistrationData's encoder
        }
    }
}

// --- MODIFY Gender Enum ---
enum Gender: String, CaseIterable, Identifiable {
    // Use display-friendly rawValues for Picker
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"

    var id: String { self.rawValue }

    // Add computed property for the backend value
    var backendValue: String {
        switch self {
        case .male: return "male"
        case .female: return "female"
        case .other: return "other"
        case .preferNotToSay: return "prefer_not_to_say" // Correct backend value
        }
    }
}
