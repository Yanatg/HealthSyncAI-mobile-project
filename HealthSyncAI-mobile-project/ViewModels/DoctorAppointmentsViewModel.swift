// HealthSyncAI-mobile-project/ViewModels/DoctorAppointmentsViewModel.swift
// NEW FILE
import Foundation
import Combine

@MainActor
class DoctorAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let networkManager = NetworkManager.shared

    func fetchAppointments() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedAppointments = try await networkManager.fetchDoctorAppointments()
                // Sort appointments, newest first might be useful
                self.appointments = fetchedAppointments.sorted {
                    guard let date1 = ISO8601DateFormatter().date(from: $0.startTime),
                          let date2 = ISO8601DateFormatter().date(from: $1.startTime) else {
                        return false // Keep original order if parsing fails
                    }
                    return date1 > date2
                }
                print("✅ Fetched \(self.appointments.count) appointments for doctor.")
            } catch let error as NetworkError {
                errorMessage = "Failed to load appointments: \(error.localizedDescription)"
                print("❌ NetworkError fetching appointments: \(error)")
            } catch {
                errorMessage = "An unexpected error occurred while fetching appointments: \(error.localizedDescription)"
                print("❌ Unexpected error fetching appointments: \(error)")
            }
            isLoading = false
        }
    }
}
