import Foundation
import Combine

@MainActor
class DoctorAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let networkManager = NetworkManager.shared
    private var hasFetchedOnce = false // Prevent fetching multiple times on appear if not needed

    func fetchAppointments(showLoadingIndicator: Bool = true) {
         // Avoid fetching again if already loading
         guard !isLoading else { return }

         if showLoadingIndicator {
            isLoading = true
         }
        errorMessage = nil

        Task {
            do {
                let fetchedAppointments = try await networkManager.fetchDoctorAppointments()
                // Sort appointments: upcoming first, then past sorted by date descending
                self.appointments = fetchedAppointments.sorted { app1, app2 in
                    // Use the non-lazy computed property 'startDate'
                    let date1 = app1.startDate
                    let date2 = app2.startDate

                    // Handle potential nil dates during sorting
                    guard let d1 = date1, let d2 = date2 else {
                        return date1 != nil // Place valid dates before invalid ones
                    }

                    // Prioritize scheduled future appointments
                    let isApp1Upcoming = app1.status.lowercased() == "scheduled" && d1 > Date()
                    let isApp2Upcoming = app2.status.lowercased() == "scheduled" && d2 > Date()

                    if isApp1Upcoming && !isApp2Upcoming { return true }
                    if !isApp1Upcoming && isApp2Upcoming { return false }

                    // If both are upcoming or both are past, sort by date descending
                    return d1 > d2
                }
                hasFetchedOnce = true // Mark that initial fetch is done
                print("✅ Fetched \(self.appointments.count) appointments for doctor.")
            } catch let error as NetworkError {
                errorMessage = "Failed to load appointments: \(error.localizedDescription)"
                print("❌ NetworkError fetching appointments: \(error)")
                 print("Detailed NetworkError: \(error.errorDescription ?? "No details")") // Print detailed desc
            } catch {
                errorMessage = "An unexpected error occurred while fetching appointments: \(error.localizedDescription)"
                print("❌ Unexpected error fetching appointments: \(error)")
            }
             // Ensure isLoading is turned off even if it wasn't set (e.g., background refresh)
             if showLoadingIndicator || isLoading {
                isLoading = false
             }
        }
    }

     // Call this from onAppear or a refresh button
     func initialFetch() {
         if !hasFetchedOnce {
             fetchAppointments(showLoadingIndicator: true)
         }
     }
}
