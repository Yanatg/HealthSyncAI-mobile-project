// HealthSyncAI-mobile-project/ViewModels/BookingViewModel.swift
// NEW FILE (within a ViewModels/Chat subfolder if desired)
import Foundation
import Combine
import SwiftUI // For Date

@MainActor
class BookingViewModel: ObservableObject {
    @Published var doctors: [Doctor] = []
    @Published var selectedDoctor: Doctor? = nil
    @Published var selectedDate = Date() // Use Date for DatePicker
    @Published var selectedTimeSlot: String? = nil // e.g., "10:30 AM"

    @Published var isLoadingDoctors: Bool = false
    @Published var doctorError: String? = nil

    // Hardcoded time slots as in the React component
    let availableTimeSlots = [
        "10:30 AM", "11:30 AM", "02:30 PM", "03:00 PM",
        "03:30 PM", "04:30 PM", "05:00 PM", "05:30 PM"
    ]

    private let networkManager = NetworkManager.shared

    init() {
        fetchDoctors()
    }

    func fetchDoctors() {
        isLoadingDoctors = true
        doctorError = nil

        Task {
            do {
                let fetchedDoctors = try await networkManager.fetchDoctors()
                self.doctors = fetchedDoctors
                // Auto-select the first doctor if available
                if let firstDoctor = fetchedDoctors.first {
                    self.selectedDoctor = firstDoctor
                }
                print("✅ Fetched \(fetchedDoctors.count) doctors.")
            } catch let error as NetworkError {
                doctorError = "Failed to load doctors: \(error.localizedDescription)"
                print("❌ NetworkError fetching doctors: \(error)")
            } catch {
                doctorError = "An unexpected error occurred: \(error.localizedDescription)"
                print("❌ Unexpected error fetching doctors: \(error)")
            }
            isLoadingDoctors = false
        }
    }

    func selectDoctor(_ doctor: Doctor) {
        selectedDoctor = doctor
    }

    func selectTime(_ time: String) {
        selectedTimeSlot = time
    }

    // --- Helper to format Date and Time for API ---
    // Returns (isoStartTime, isoEndTime) or nil if invalid selection
    func getFormattedAppointmentTimes() -> (String, String)? {
        guard let timeSlot = selectedTimeSlot else {
            print("❌ Cannot format time: Time slot not selected.")
            return nil
        }

        // 1. Combine selectedDate (day, month, year) with timeSlot (hour, minute, am/pm)
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        // 2. Parse the timeSlot string
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a" // e.g., "10:30 AM"
        guard let timeDate = timeFormatter.date(from: timeSlot) else {
            print("❌ Cannot format time: Failed to parse time slot '\(timeSlot)'")
            return nil
        }
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)

        // 3. Create the final start time Date object
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        // Use current timeZone temporarily, ISO8601Encoder will handle UTC conversion
        combinedComponents.timeZone = TimeZone.current

        guard let startTime = calendar.date(from: combinedComponents) else {
            print("❌ Cannot format time: Failed to create start date from components.")
            return nil
        }

        // 4. Calculate end time (assuming 1-hour duration like React code)
        guard let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) else {
            print("❌ Cannot format time: Failed to calculate end time.")
            return nil
        }

        // 5. Format as ISO 8601 strings (UTC is standard)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Include fractional seconds if needed by backend

        let startTimeString = isoFormatter.string(from: startTime)
        let endTimeString = isoFormatter.string(from: endTime)

        return (startTimeString, endTimeString)
    }
}
