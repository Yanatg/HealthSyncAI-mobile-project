// HealthSyncAI-mobile-project/ViewModels/MyAppointmentsViewModel.swift
// NEW FILE (or copy/rename/modify DoctorAppointmentsViewModel)

import Foundation
import Combine

@MainActor // Ensure UI updates are on the main thread
class MyAppointmentsViewModel: ObservableObject {

    @Published var appointments: [Appointment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let networkManager = NetworkManager.shared
    // Optional: Inject AppState if needed for logout on auth error
    // weak var appState: AppState?
    private var hasFetchedOnce = false // Prevent fetching multiple times on appear if not needed

    // Initial fetch can be triggered by the view's onAppear using initialFetch()
    init(/* appState: AppState? = nil */) {
       // self.appState = appState
       // Don't fetch in init; let the view trigger it via onAppear/initialFetch
    }

    func fetchAppointments(showLoadingIndicator: Bool = true) {
         // Avoid fetching again if already loading
         guard !isLoading else { return }

         if showLoadingIndicator {
            isLoading = true
         }
        errorMessage = nil

        Task {
            do {
                // *** Use the NetworkManager function intended for fetching patient appointments ***
                // This relies on the JWT token sent by the generic 'request' function
                // to ensure the backend returns the correct user's data.
                let fetchedAppointments = try await networkManager.fetchPatientAppointments()

                // Sort appointments: upcoming first, then past sorted by date descending
                // (Using the same logic as the doctor view seems appropriate here)
                self.appointments = fetchedAppointments.sorted { app1, app2 in
                    // Use the computed property 'startDate' from Appointment model
                    let date1 = app1.startDate
                    let date2 = app2.startDate

                    // Handle potential nil dates during sorting if parsing failed
                    guard let d1 = date1, let d2 = date2 else {
                        return date1 != nil // Place valid dates before invalid ones
                    }

                    // Status check needs to be safe (handle potential variations)
                    let app1StatusLower = app1.status.lowercased()
                    let app2StatusLower = app2.status.lowercased()

                    // Consider both "scheduled" and "confirmed" (or others) as upcoming
                    let isApp1Upcoming = (app1StatusLower == "scheduled" || app1StatusLower == "confirmed") && d1 > Date()
                    let isApp2Upcoming = (app2StatusLower == "scheduled" || app2StatusLower == "confirmed") && d2 > Date()

                    if isApp1Upcoming && !isApp2Upcoming { return true } // App1 is upcoming, App2 is not
                    if !isApp1Upcoming && isApp2Upcoming { return false } // App2 is upcoming, App1 is not

                    // If both are upcoming or both are past/other statuses, sort by date descending (newest first)
                    return d1 > d2
                }
                hasFetchedOnce = true // Mark that initial fetch is done
                print("✅ Fetched \(self.appointments.count) appointments for PATIENT.") // Log context

            } catch let error as NetworkError {
                errorMessage = "Failed to load your appointments: \(error.localizedDescription)"
                print("❌ NetworkError fetching PATIENT appointments: \(error)") // Log context
                print("Detailed NetworkError: \(error.errorDescription ?? "No details")")
                // Optional: Handle unauthorized for logout
                // if case .unauthorized = error { appState?.logout() }
            } catch {
                errorMessage = "An unexpected error occurred while fetching your appointments."
                print("❌ Unexpected error fetching PATIENT appointments: \(error)") // Log context
            }
             // Ensure isLoading is turned off
             if showLoadingIndicator || isLoading {
                isLoading = false
             }
        }
    }

     // Call this from the View's .onAppear or a refresh action
     func initialFetch() {
         // Fetch only if it hasn't been fetched before to avoid redundant calls on reappear
         if !hasFetchedOnce {
             fetchAppointments(showLoadingIndicator: true)
         }
         // If you ALWAYS want to check for updates when the view appears, remove the !hasFetchedOnce check
         // or provide a separate function.
     }

     // Add a dedicated refresh function for SwiftUI's .refreshable
     func refreshAppointments() {
          hasFetchedOnce = false // Allow fetch to run again with loading indicator
          fetchAppointments(showLoadingIndicator: true) // Explicitly show loader on refresh
     }
}

// Note: No need to redefine the helper date formatters if they are accessible
// from the Appointment model file (e.g., if defined globally or static).
// If they are private in Appointment.swift, you might need to redefine them here
// or make them accessible (e.g., put them in a shared DateUtility file).
