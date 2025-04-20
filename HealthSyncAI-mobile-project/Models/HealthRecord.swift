// HealthSyncAI-mobile-project/Models/HealthRecord.swift
import Foundation

// Corresponds to HealthRecord in React lib/type.ts and API response
struct HealthRecord: Codable, Identifiable {
    let id: Int
    let patientId: Int
    let doctorId: Int
    let title: String
    let summary: String
    let recordType: String
    let symptoms: [Symptom]? // Array of Symptom structs
    let diagnosis: [Diagnosis]? // Array of Diagnosis structs
    let treatmentPlan: [TreatmentPlan]? // Array of TreatmentPlan structs
    let medication: [Medication]? // Array of Medication structs
    let triageRecommendation: String?
    let confidenceScore: Double?
    let createdAt: String
    let updatedAt: String

    // CodingKeys for HealthRecord (Relies on .convertFromSnakeCase strategy)
    // No changes needed here from the previous fix
    enum CodingKeys: String, CodingKey {
        case id, title, summary, symptoms, diagnosis, medication
        case patientId
        case doctorId
        case recordType
        case treatmentPlan
        case triageRecommendation
        case confidenceScore
        case createdAt
        case updatedAt
    }

    // Helpers for display formatting (Keep as is)
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
        // Allow for potential fractional seconds
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
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

// --- Nested Structures ---

// *** Symptom: Add custom init to ignore client-side id ***
struct Symptom: Codable, Identifiable {
    var id = UUID() // Client-side only for Identifiable
    var name: String
    var severity: Int?
    var duration: String?
    var description: String?

    // Define CodingKeys *only* for properties coming from JSON
    enum CodingKeys: String, CodingKey {
        case name, severity, duration, description
        // DO NOT include 'id' here
    }

    // Custom decoder init
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        severity = try container.decodeIfPresent(Int.self, forKey: .severity) // Use decodeIfPresent for optionals
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        // 'id' is NOT decoded, it keeps its default UUID() value
    }

    // Add a default initializer if needed elsewhere in your code (e.g., for creating new empty ones)
     init(id: UUID = UUID(), name: String = "", severity: Int? = nil, duration: String? = nil, description: String? = nil) {
         self.id = id
         self.name = name
         self.severity = severity
         self.duration = duration
         self.description = description
     }
}

// *** Diagnosis: Add custom init to ignore client-side id ***
struct Diagnosis: Codable, Identifiable {
    var id = UUID() // Client-side only
    var name: String
    var icd10Code: String?
    var description: String?
    var confidence: Double?

    // Define CodingKeys *only* for properties coming from JSON
    // Relies on .convertFromSnakeCase strategy for icd10Code
    enum CodingKeys: String, CodingKey {
        case name, description, confidence
        case icd10Code // Strategy handles icd10_code -> icd10Code
        // DO NOT include 'id' here
    }

     // Custom decoder init
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         name = try container.decode(String.self, forKey: .name)
         icd10Code = try container.decodeIfPresent(String.self, forKey: .icd10Code)
         description = try container.decodeIfPresent(String.self, forKey: .description)
         confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
         // 'id' is NOT decoded
     }

     // Add a default initializer if needed
      init(id: UUID = UUID(), name: String = "", icd10Code: String? = nil, description: String? = nil, confidence: Double? = nil) {
          self.id = id
          self.name = name
          self.icd10Code = icd10Code
          self.description = description
          self.confidence = confidence
      }
}

// *** TreatmentPlan: Add custom init to ignore client-side id ***
struct TreatmentPlan: Codable, Identifiable {
    var id = UUID() // Client-side only
    var description: String
    var duration: String?
    var followUp: String?

    // Define CodingKeys *only* for properties coming from JSON
    // Relies on .convertFromSnakeCase strategy for followUp
    enum CodingKeys: String, CodingKey {
        case description, duration
        case followUp // Strategy handles follow_up -> followUp
        // DO NOT include 'id' here
    }

    // Custom decoder init
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         description = try container.decode(String.self, forKey: .description)
         duration = try container.decodeIfPresent(String.self, forKey: .duration)
         followUp = try container.decodeIfPresent(String.self, forKey: .followUp)
         // 'id' is NOT decoded
     }

     // Add a default initializer if needed
     init(id: UUID = UUID(), description: String = "", duration: String? = nil, followUp: String? = nil) {
         self.id = id
         self.description = description
         self.duration = duration
         self.followUp = followUp
     }
}

// *** Medication: Add custom init to ignore client-side id ***
struct Medication: Codable, Identifiable {
    var id = UUID() // Client-side only
    var name: String
    var dosage: String
    var frequency: String
    var duration: String?
    var notes: String?

    // Define CodingKeys *only* for properties coming from JSON
    enum CodingKeys: String, CodingKey {
         case name, dosage, frequency, duration, notes
         // DO NOT include 'id' here
     }

     // Custom decoder init
     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         name = try container.decode(String.self, forKey: .name)
         dosage = try container.decode(String.self, forKey: .dosage)
         frequency = try container.decode(String.self, forKey: .frequency)
         duration = try container.decodeIfPresent(String.self, forKey: .duration)
         notes = try container.decodeIfPresent(String.self, forKey: .notes)
         // 'id' is NOT decoded
     }

      // Add a default initializer if needed
      init(id: UUID = UUID(), name: String = "", dosage: String = "", frequency: String = "", duration: String? = nil, notes: String? = nil) {
          self.id = id
          self.name = name
          self.dosage = dosage
          self.frequency = frequency
          self.duration = duration
          self.notes = notes
      }
}
