// HealthSyncAI-mobile-project/Models/HealthRecord.swift
// NEW FILE
import Foundation

// Corresponds to HealthRecord in React lib/type.ts and API response
struct HealthRecord: Codable, Identifiable {
    let id: Int
    let patientId: Int
    let doctorId: Int
    let title: String
    let summary: String
    let recordType: String // "doctor_note", "at_triage", etc.
    let symptoms: [Symptom]?
    let diagnosis: [Diagnosis]?
    let treatmentPlan: [TreatmentPlan]?
    let medication: [Medication]?
    let triageRecommendation: String?
    let confidenceScore: Double? // API uses float/double
    let createdAt: String // ISO Date String
    let updatedAt: String // ISO Date String

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case doctorId = "doctor_id"
        case title
        case summary
        case recordType = "record_type"
        case symptoms
        case diagnosis
        case treatmentPlan = "treatment_plan"
        case medication
        case triageRecommendation = "triage_recommendation"
        case confidenceScore = "confidence_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Helpers for display formatting
    var formattedCreatedAt: String { formatDate(createdAt) }
    var formattedUpdatedAt: String { formatDate(updatedAt) }
    var formattedConfidence: String? {
        guard let score = confidenceScore else { return nil }
        return String(format: "%.0f%%", score * 100)
    }
    var formattedRecordType: String {
        recordType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func formatDate(_ dateString: String) -> String {
        // Use a shared date formatter or create one locally
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        // Fallback for slightly different ISO formats if needed
        let alternativeFormatter = ISO8601DateFormatter()
        alternativeFormatter.formatOptions = .withInternetDateTime
        if let altDate = alternativeFormatter.date(from: dateString) {
             let displayFormatter = DateFormatter()
             displayFormatter.dateStyle = .long
             displayFormatter.timeStyle = .short
             return displayFormatter.string(from: altDate)
         }
        print("⚠️ Could not parse health record date: \(dateString)")
        return dateString // Fallback
    }
}

// Nested Structures (must also be Codable)
// Using Identifiable where appropriate for ForEach loops in SwiftUI
struct Symptom: Codable, Identifiable {
    var id = UUID() // Make identifiable for SwiftUI lists
    var name: String
    var severity: Int? // API uses number or null
    var duration: String?
    var description: String?

     // Add CodingKeys if API uses snake_case
     enum CodingKeys: String, CodingKey {
         case name, severity, duration, description
     }
}

struct Diagnosis: Codable, Identifiable {
    var id = UUID()
    var name: String
    var icd10Code: String?
    var description: String?
    var confidence: Double? // API uses float/double

    enum CodingKeys: String, CodingKey {
        case name
        case icd10Code = "icd10_code"
        case description, confidence
    }
}

struct TreatmentPlan: Codable, Identifiable {
    var id = UUID()
    var description: String
    var duration: String?
    var followUp: String?

    enum CodingKeys: String, CodingKey {
        case description, duration
        case followUp = "follow_up"
    }
}

struct Medication: Codable, Identifiable {
    var id = UUID()
    var name: String
    var dosage: String
    var frequency: String
    var duration: String? // Optional based on React type
    var notes: String?

     // Add CodingKeys if API uses snake_case
     enum CodingKeys: String, CodingKey {
         case name, dosage, frequency, duration, notes
     }
}
