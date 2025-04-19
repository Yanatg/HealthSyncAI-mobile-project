// HealthSyncAI-mobile-project/Views/Doctor/DoctorAppointmentsView.swift
// NEW FILE (Create a 'Doctor' subfolder within Views if desired)
import SwiftUI

struct DoctorAppointmentsView: View {
    @StateObject private var viewModel = DoctorAppointmentsViewModel()

    var body: some View {
        NavigationView { // Or NavigationStack for newer iOS versions
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Appointments...")
                        .padding()
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if viewModel.appointments.isEmpty {
                    Text("No appointments found.")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.appointments) { appointment in
                            NavigationLink(destination: PatientRecordsView(patientId: appointment.patientId)) {
                                AppointmentRow(appointment: appointment)
                            }
                        }
                    }
                    .listStyle(.plain) // Or choose another style
                }
            }
            .navigationTitle("Your Appointments")
            .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button {
                         viewModel.fetchAppointments()
                     } label: {
                         Image(systemName: "arrow.clockwise")
                     }
                     .disabled(viewModel.isLoading)
                 }
             }
            .onAppear {
                // Fetch only if the list is empty initially
                if viewModel.appointments.isEmpty {
                    viewModel.fetchAppointments()
                }
            }
        }
        // On iOS 16+ use NavigationStack instead of NavigationView for better performance
        // .navigationViewStyle(.stack) // Recommended for NavigationView on multi-column layouts if needed
    }
}

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

            Text(appointment.formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(appointment.formattedTimeRange)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let url = appointment.telemedicineUrl, !url.isEmpty {
                HStack {
                    Image(systemName: "video.fill")
                    Text("Telemedicine")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 5) // Add some padding within the row
    }
}

struct DoctorAppointmentsView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorAppointmentsView()
    }
}
