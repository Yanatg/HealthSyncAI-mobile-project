// HealthSyncAI-mobile-project/Models/Appointment.swift
// NEW FILE
import Foundation

struct Appointment: Codable, Identifiable {
    let id: Int
    let patientId: Int
    let doctorId: Int
    let startTime: String // Keep as ISO string, format in View/ViewModel
    let endTime: String   // Keep as ISO string, format in View/ViewModel
    let status: String // "scheduled", "completed", "cancelled", "no_show"
    let telemedicineUrl: String?
    // health_record_id is optional and might not always be present directly

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case doctorId = "doctor_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case status
        case telemedicineUrl = "telemedicine_url"
        // case healthRecordId = "health_record_id" // Only map if consistently present
    }

    // Helper for date formatting (can be moved to Utils)
    var formattedStartTime: String {
        formatDate(startTime)
    }

    var formattedEndTime: String {
        formatDate(endTime)
    }

    var formattedDate: String {
        formatDate(startTime, style: .date)
    }

    var formattedTimeRange: String {
        let start = formatDate(startTime, style: .time)
        let end = formatDate(endTime, style: .time)
        return "\(start) - \(end)"
    }

    private func formatDate(_ dateString: String, style: DateStyle = .dateTime) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Adjust based on your API's exact ISO format

        guard let date = formatter.date(from: dateString) else {
            // Fallback for slightly different ISO formats if needed
            let alternativeFormatter = ISO8601DateFormatter()
            alternativeFormatter.formatOptions = .withInternetDateTime
            guard let altDate = alternativeFormatter.date(from: dateString) else {
                print("⚠️ Could not parse date: \(dateString)")
                return dateString // Return original string if parsing fails
            }
            return formatDisplayDate(altDate, style: style)
        }
        return formatDisplayDate(date, style: style)
    }

    private func formatDisplayDate(_ date: Date, style: DateStyle) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: "en_US_POSIX") // Consistent locale
        switch style {
        case .dateTime:
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
        case .date:
            displayFormatter.dateStyle = .long // "MMMM d, yyyy"
            displayFormatter.timeStyle = .none
        case .time:
            displayFormatter.dateStyle = .none
            displayFormatter.timeStyle = .short // "h:mm a"
        }
        return displayFormatter.string(from: date)
    }

    enum DateStyle {
        case dateTime, date, time
    }

    // Helper to determine status color (adapt as needed)
    var statusColor: Color {
        switch status.lowercased() {
        case "scheduled": return .blue
        case "completed": return .green
        case "cancelled": return .red
        case "no_show": return .orange
        default: return .gray
        }
    }
}

// Add SwiftUI import for Color
import SwiftUI
