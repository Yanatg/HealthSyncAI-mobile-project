import SwiftUI

struct DoctorAppointmentsView: View {
    @StateObject private var viewModel = DoctorAppointmentsViewModel()
    @EnvironmentObject private var appState: AppState // Get AppState from environment

    var body: some View {
        NavigationView {
            Group {
                // ... (Loading/Error/List logic remains the same)
                if viewModel.isLoading && viewModel.appointments.isEmpty {
                    ProgressView("Loading Appointments...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                     VStack { /* Error handling view */ }
                     .padding()
                } else if viewModel.appointments.isEmpty && !viewModel.isLoading {
                    Text("No appointments found.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.appointments) { appointment in
                            NavigationLink(destination: PatientRecordsView(patientId: appointment.patientId)
                                .environmentObject(appState)) { // Pass environment object down if needed
                                AppointmentRow(appointment: appointment)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        viewModel.fetchAppointments(showLoadingIndicator: false)
                    }
                }
            }
            .navigationTitle("Appointments")
            .toolbar {
                 ToolbarItem(placement: .navigationBarLeading) {
                     // Use appState.logout() for the action
                     Button("Logout") {
                         appState.logout() // Call logout on the central state object
                     }
                     .tint(.red)
                 }
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button {
                         viewModel.fetchAppointments(showLoadingIndicator: true)
                     } label: {
                         Image(systemName: "arrow.clockwise")
                     }
                     .disabled(viewModel.isLoading)
                 }
             }
            .onAppear {
                print("DoctorAppointmentsView appeared. Fetching initial data if needed.")
                viewModel.initialFetch()
            }
        }
        // REMOVE: performLogout() function from this view - logic moved to AppState
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
            .environmentObject(AppState()) // Provide a dummy AppState for preview
    }
}
