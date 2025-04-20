// HealthSyncAI-mobile-project/Views/Doctor/DoctorAppointmentsView.swift
import SwiftUI

struct DoctorAppointmentsView: View {
    @StateObject private var viewModel = DoctorAppointmentsViewModel()

    var body: some View {
        NavigationView { // Or NavigationStack
            Group { // Use Group to apply modifiers conditionally
                if viewModel.isLoading && viewModel.appointments.isEmpty { // Show loading only on initial load
                    ProgressView("Loading Appointments...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack {
                         Text("Error")
                            .font(.headline)
                         Text(error) // Display the detailed error from NetworkManager
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                         Button("Retry") {
                             viewModel.fetchAppointments(showLoadingIndicator: true)
                         }
                         .buttonStyle(.bordered)
                         Spacer() // Push content to top
                    }
                     .padding()
                } else if viewModel.appointments.isEmpty && !viewModel.isLoading { // Show only if not loading and empty
                    Text("No appointments found.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.appointments) { appointment in
                            // Ensure patientId is correctly passed
                            NavigationLink(destination: PatientRecordsView(patientId: appointment.patientId)) {
                                AppointmentRow(appointment: appointment)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable { // Add pull-to-refresh
                        viewModel.fetchAppointments(showLoadingIndicator: false) // Don't show big spinner on refresh
                    }
                }
            }
            .navigationTitle("Appointments")
             .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) { // Example Logout Button
                     Button("Logout") {
                         performLogout()
                     }
                     .tint(.red)
                 }
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button {
                         viewModel.fetchAppointments(showLoadingIndicator: true) // Manual refresh shows loading
                     } label: {
                         Image(systemName: "arrow.clockwise")
                     }
                     .disabled(viewModel.isLoading) // Disable while loading
                 }
             }
            .onAppear {
                 print("DoctorAppointmentsView appeared. Fetching initial data if needed.")
                viewModel.initialFetch() // Fetch data when the view appears
            }
        }
        // .navigationViewStyle(.stack) // If needed
    }

     // Example Logout Function (Should ideally be managed globally, e.g., in App file)
     func performLogout() {
         print("Performing logout from DoctorAppointmentsView...")
         KeychainHelper.standard.clearAuthCredentials()
         // This needs to communicate back to the App struct to change the root view
         // Often done via @EnvironmentObject or passing bindings down.
         // For now, just clearing keychain. App state needs to be updated.
         // A simple way for now might be to force a reload or use Notifications.
         // Forcing requires access to window scene, complex.
         // Let's assume the App checks keychain on next launch/resume.
         // Ideally: Add `@EnvironmentObject var appState: AppState` and set `appState.isLoggedIn = false`
     }
}

// AppointmentRow remains the same, but ensure display formatting is correct
struct AppointmentRow: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Patient ID: \(appointment.patientId)")
                    .font(.headline)
                Spacer()
                Text(appointment.status.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(appointment.statusColor.opacity(0.2))
                    .foregroundColor(appointment.statusColor)
                    .cornerRadius(5)
            }

             Text(appointment.displayDate) // Use helper
                .font(.subheadline)
                .foregroundColor(.secondary)

             Text(appointment.displayTimeRange) // Use helper
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let urlString = appointment.telemedicineUrl, let url = URL(string: urlString), !urlString.isEmpty {
                // Make the telemedicine link tappable
                 Link(destination: url) {
                     HStack {
                         Image(systemName: "video.fill")
                         Text("Telemedicine Link")
                     }
                     .font(.caption)
                     .foregroundColor(.blue) // Use standard link color
                 }
                 .buttonStyle(.plain) // Prevent the whole row from highlighting like a button
            }
        }
        .padding(.vertical, 5)
    }
}

struct DoctorAppointmentsView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorAppointmentsView()
    }
}
