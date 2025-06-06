import Foundation
import SwiftUI // Needed for Color

struct Appointment: Codable, Identifiable {
    let id: Int
    let patientId: Int // Keep Swift property as camelCase
    let doctorId: Int  // Keep Swift property as camelCase
    let startTime: String // Keep as ISO string for decoding
    let endTime: String   // Keep as ISO string for decoding
    let status: String // "scheduled", "completed", "cancelled", "no_show" etc.
    let telemedicineUrl: String? // This should be optional

    // --- UPDATED CodingKeys ---
    // Explicitly map the snake_case JSON keys to your camelCase Swift properties
    enum CodingKeys: String, CodingKey {
        case id               // JSON 'id' maps to Swift 'id'
        case patientId = "patient_id" // JSON 'patient_id' maps to Swift 'patientId'
        case doctorId = "doctor_id"   // JSON 'doctor_id' maps to Swift 'doctorId'
        case startTime = "start_time" // JSON 'start_time' maps to Swift 'startTime'
        case endTime = "end_time"     // JSON 'end_time' maps to Swift 'endTime'
        case status                   // JSON 'status' maps to Swift 'status'
        case telemedicineUrl = "telemedicine_url" // JSON 'telemedicine_url' maps to Swift 'telemedicineUrl'
    }
    // --- END UPDATE ---

    // --- Computed Properties (No change needed here) ---

    // Calculate the start Date object when needed
    var startDate: Date? {
        parseISO8601String(startTime)
    }

    // Calculate the end Date object when needed
    var endDate: Date? {
        parseISO8601String(endTime)
    }

    // --- Display Formatting Helpers (No change needed here) ---

    var displayDate: String {
        guard let date = startDate else { return "Invalid Date" } // Use the computed property
        return DateFormatter.displayDateFormatter.string(from: date)
    }

    var displayTimeRange: String {
        guard let start = startDate, let end = endDate else { // Use computed properties
            return "Invalid Time"
        }
        let startStr = DateFormatter.displayTimeFormatter.string(from: start)
        let endStr = DateFormatter.displayTimeFormatter.string(from: end)
        return "\(startStr) - \(endStr)"
    }

    // Helper for status color (remains the same)
    var statusColor: Color {
        switch status.lowercased() {
        case "scheduled": return .blue
        case "completed": return .green
        case "cancelled": return .red
        case "no_show": return .orange
        default: return .gray
        }
    }

    // Consolidated ISO8601 parsing function (remains the same)
    private func parseISO8601String(_ dateString: String) -> Date? {
        // Try with fractional seconds first
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFractional.date(from: dateString) {
            return date
        }

        // Fallback without fractional seconds
        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFractional.date(from: dateString) {
            return date
        }

        print("⚠️ Could not parse date string: \(dateString)")
        return nil // Return nil if parsing fails completely
    }
}

// CreateAppointmentRequest remains the same
struct CreateAppointmentRequest: Codable {
    let doctorId: Int
    let startTime: String // ISO 8601 format string
    let endTime: String   // ISO 8601 format string
    let telemedicineUrl: String

    enum CodingKeys: String, CodingKey {
        case doctorId = "doctor_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case telemedicineUrl = "telemedicine_url"
    }
}

// DateFormatter extension remains the same
extension DateFormatter {
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long // e.g., "July 22, 2024"
        formatter.timeStyle = .none
        return formatter
    }()

    static let displayTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short // e.g., "10:30 AM"
        return formatter
    }()
}
