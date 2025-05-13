import Foundation
import Combine
import SwiftUI

@MainActor
class BookingViewModel: ObservableObject {
    @Published var doctors: [Doctor] = []
    @Published var selectedDoctor: Doctor? = nil
    @Published var selectedDate = Date() // Use Date for DatePicker
    @Published var selectedTimeSlot: String? = nil // e.g., "10:30 AM"

    @Published var isLoadingDoctors: Bool = false
    @Published var doctorError: String? = nil

    @Published var isBooking: Bool = false // Tracks if the booking network call is active

    // Hardcoded time slots as in the React component
    let availableTimeSlots = [
        "10:30 AM", "11:30 AM", "02:30 PM", "03:00 PM",
        "03:30 PM", "04:30 PM", "05:00 PM", "05:30 PM"
    ]

    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>() // If using Combine internally

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
                 print("✅ [BookingVM] Fetched \(fetchedDoctors.count) doctors.")
            } catch let error as NetworkError {
                doctorError = "Failed to load doctors: \(error.localizedDescription)"
                 print("❌ [BookingVM] NetworkError fetching doctors: \(error)")
            } catch {
                doctorError = "An unexpected error occurred: \(error.localizedDescription)"
                 print("❌ [BookingVM] Unexpected error fetching doctors: \(error)")
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
             print("❌ [BookingVM] Cannot format time: Time slot not selected.")
            return nil
        }

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"
        guard let timeDate = timeFormatter.date(from: timeSlot) else {
             print("❌ [BookingVM] Cannot format time: Failed to parse time slot '\(timeSlot)'")
            return nil
        }
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timeDate)
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.timeZone = TimeZone.current // ISO formatter handles UTC conversion
        guard let startTime = calendar.date(from: combinedComponents) else {
             print("❌ [BookingVM] Cannot format time: Failed to create start date from components.")
            return nil
        }
        guard let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) else { // Assuming 1 hour duration
             print("❌ [BookingVM] Cannot format time: Failed to calculate end time.")
            return nil
        }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let startTimeString = isoFormatter.string(from: startTime)
        let endTimeString = isoFormatter.string(from: endTime)
        return (startTimeString, endTimeString)
    }

    // --- ADDED: Method to perform the booking network call ---
    // This method should be called BY ChatViewModel
    func performBooking(requestData: CreateAppointmentRequest) async throws -> Appointment {
        // Set booking state to true BEFORE the network call
        isBooking = true
        // Ensure isBooking is set back to false when the function exits,
        // whether it succeeds or throws an error.
        defer {
             print("🔄 [BookingVM] Setting isBooking back to false (defer).")
             isBooking = false
        }

        print("⏳ [BookingVM] Attempting to create appointment...")
        // The actual network call - let it throw errors upwards
        let createdAppointment = try await networkManager.createAppointment(requestData: requestData)
        print("✅ [BookingVM] Appointment created successfully! ID: \(createdAppointment.id)")
        return createdAppointment
    }
    // --- End ADDED Method ---

}
