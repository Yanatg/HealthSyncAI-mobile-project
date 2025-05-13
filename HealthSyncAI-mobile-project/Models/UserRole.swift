import Foundation

// Define the UserRole enum
enum UserRole: String, CaseIterable, Identifiable {
    case patient = "Patient"
    case doctor = "Doctor"

    // Conformance to Identifiable for ForEach loop
    var id: String { self.rawValue }
}
