import Foundation

// Structure matching the JSON body needed for the POST /api/health-record/doctor-note endpoint
// Based on components/HealthRecord.tsx and types/healthRecord.ts
struct CreateDoctorNoteRequestBody: Codable {
    let title: String
    let summary: String
    let patientId: Int
    let symptoms: [SymptomRequestBody] // Use specific request body structs
    let diagnosis: [DiagnosisRequestBody]
    let treatmentPlan: [TreatmentPlanRequestBody]
    let medication: [MedicationRequestBody]

    // IMPORTANT: Only include record_type if the API *requires* it during creation.
    // Often, the backend sets this automatically based on the endpoint.
    // let recordType: String = "doctor_note"

    enum CodingKeys: String, CodingKey {
        case title, summary
        case patientId = "patient_id" // Ensure correct key mapping
        case symptoms, diagnosis
        case treatmentPlan = "treatment_plan"
        case medication
        // case recordType = "record_type"
    }
}

// Nested structs for the request body, mirroring the main structs but potentially simplified
// (e.g., without 'id' if it's not sent in the request)
struct SymptomRequestBody: Codable {
    var name: String
    var severity: Int?
    var duration: String?
    var description: String?
}

struct DiagnosisRequestBody: Codable {
    var name: String
    var icd10Code: String?
    var description: String?
    // Confidence is usually calculated/set by backend, not sent in request

    enum CodingKeys: String, CodingKey {
        case name
        case icd10Code = "icd10_code"
        case description
    }
}

struct TreatmentPlanRequestBody: Codable {
    var description: String
    var duration: String?
    var followUp: String?

    enum CodingKeys: String, CodingKey {
        case description, duration
        case followUp = "follow_up"
    }
}

struct MedicationRequestBody: Codable {
    var name: String
    var dosage: String
    var frequency: String
    var duration: String?
    var notes: String?
}

// --- Helper Extension for Conversion ---
// Add this inside the CreateDoctorNoteViewModel or where you construct the request body
extension Array where Element == Symptom {
    func toRequestBodies() -> [SymptomRequestBody] {
        self.map { SymptomRequestBody(name: $0.name, severity: $0.severity, duration: $0.duration, description: $0.description) }
    }
}
extension Array where Element == Diagnosis {
    func toRequestBodies() -> [DiagnosisRequestBody] {
        self.map { DiagnosisRequestBody(name: $0.name, icd10Code: $0.icd10Code, description: $0.description) }
    }
}
extension Array where Element == TreatmentPlan {
     func toRequestBodies() -> [TreatmentPlanRequestBody] {
         self.map { TreatmentPlanRequestBody(description: $0.description, duration: $0.duration, followUp: $0.followUp) }
     }
 }
extension Array where Element == Medication {
    func toRequestBodies() -> [MedicationRequestBody] {
        self.map { MedicationRequestBody(name: $0.name, dosage: $0.dosage, frequency: $0.frequency, duration: $0.duration, notes: $0.notes) }
    }
}
