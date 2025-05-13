import SwiftUI

struct MyAppointmentsView: View {
    // Create and observe the ViewModel instance
    @StateObject private var viewModel = MyAppointmentsViewModel()
    // Optional: Inject AppState if logout is handled directly by the view
    // @EnvironmentObject private var appState: AppState

    var body: some View {
        // NOTE: The NavigationView is now likely provided by the TabView setup in your App file.
        // If this view could potentially be pushed onto another stack, keep the NavigationView.
        // If it's ONLY ever used in the TabView, you might remove the NavigationView here,
        // but keeping it is generally safer for title display and potential future navigation.
        // Let's keep it for now.
        NavigationView {
            content
                .navigationTitle("My Appointments")
                .navigationBarTitleDisplayMode(.inline) // Or .large
                // Add toolbar items if needed (e.g., filter button)
        }
        // Trigger initial data fetch when the view appears
        .onAppear {
            viewModel.initialFetch()
        }
    }

    // Computed property for the main content based on ViewModel state
    @ViewBuilder
    private var content: some View {
        VStack { // Use a VStack to allow placing ProgressView/ErrorView outside the List
            if viewModel.isLoading && viewModel.appointments.isEmpty {
                // Show full-screen loading indicator only on initial load
                Spacer()
                ProgressView("Loading Appointments...")
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                // Error View
                Spacer()
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.orange)

                    Text("Error Loading Appointments")
                        .font(.headline)

                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Retry") {
                        viewModel.fetchAppointments(showLoadingIndicator: true) // Explicitly show loader on retry
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
                Spacer()
            } else if viewModel.appointments.isEmpty && !viewModel.isLoading {
                // Empty State View
                Spacer()
                Text("You have no scheduled appointments.")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            } else {
                // Appointments List
                List {
                    ForEach(viewModel.appointments) { appointment in
                        AppointmentRowView(appointment: appointment)
                            // Optional: Add tap gesture for navigation to detail view
                            // .onTapGesture { navigateToDetail(appointment) }
                    }
                }
                .listStyle(.plain) // Or .insetGrouped
                // Add pull-to-refresh
                .refreshable {
                    await Task { // Use await Task for async refresh action
                         viewModel.refreshAppointments()
                    }.value // Suppress warning about result not being used
                }
                // Show a smaller loading indicator at the top during refresh
                .overlay(alignment: .top) {
                     if viewModel.isLoading && !viewModel.appointments.isEmpty {
                         ProgressView().padding(.top)
                     }
                 }
            }
        }
    }

    // Optional: Function for navigation if tapping rows
    // func navigateToDetail(_ appointment: Appointment) {
    //     print("Navigate to detail for appointment ID: \(appointment.id)")
    //     // Implement navigation logic (e.g., using NavigationLink wrapper or coordinator pattern)
    // }
}

// MARK: - Appointment Row View

struct AppointmentRowView: View {
    let appointment: Appointment

    // Inject Doctor data if it's fetched separately, otherwise use Appointment properties
    // For now, assuming Appointment includes basic doctor info

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
             // Left column for Date/Time or Icon
             VStack(alignment: .leading, spacing: 4) {
                 Text(appointment.displayDate) // "July 22, 2024"
                     .font(.subheadline.weight(.medium))
                 Text(appointment.displayTimeRange) // "10:30 AM - 11:00 AM"
                     .font(.callout)
                     .foregroundColor(.secondary)
             }
             .frame(width: 130, alignment: .leading) // Fixed width for alignment

            // Divider (optional visual separation)
            // Divider().padding(.horizontal, 5)

            // Right column for Doctor/Status
            VStack(alignment: .leading, spacing: 6) {
                 // Placeholder for Doctor Info - NEEDS ACTUAL DOCTOR DATA
                 // You'll likely need to fetch Doctor details based on appointment.doctorId
                 // or have the backend include doctor info in the /my-appointments response.
                 // For now, display the ID as a placeholder.
                Text("Doctor ID: \(appointment.doctorId)") // <<< Replace with actual Doctor Name
                     .font(.headline)
                // Add Doctor Specialization if available
                 // Text("Specialization Placeholder")
                 //    .font(.subheadline)
                 //    .foregroundColor(.secondary)

                // Status Badge
                 Text(appointment.status.capitalized.replacingOccurrences(of: "_", with: " "))
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appointment.statusColor.opacity(0.15))
                    .foregroundColor(appointment.statusColor)
                    .clipShape(Capsule()) // Use Capsule for rounded ends
                    .padding(.top, 4)
            }

            Spacer() // Pushes content to the left
        }
        .padding(.vertical, 10) // Padding inside the row
    }
}


// MARK: - Preview

#Preview { // Use the new #Preview macro
    // Provide dummy data for the preview
    let previewViewModel = MyAppointmentsViewModel()
    previewViewModel.appointments = [
        Appointment(id: 1, patientId: 1, doctorId: 101, startTime: "2024-07-27T10:30:00Z", endTime: "2024-07-27T11:00:00Z", status: "scheduled", telemedicineUrl: nil),
        Appointment(id: 2, patientId: 1, doctorId: 102, startTime: "2024-07-20T14:00:00Z", endTime: "2024-07-20T14:30:00Z", status: "completed", telemedicineUrl: nil),
        Appointment(id: 3, patientId: 1, doctorId: 101, startTime: "2024-06-15T09:00:00Z", endTime: "2024-06-15T09:30:00Z", status: "cancelled", telemedicineUrl: nil),
        Appointment(id: 4, patientId: 1, doctorId: 103, startTime: "2024-07-29T16:00:00Z", endTime: "2024-07-29T16:30:00Z", status: "scheduled", telemedicineUrl: nil)
    ]
    // To preview loading state:
    // let loadingViewModel = MyAppointmentsViewModel()
    // loadingViewModel.isLoading = true

    // To preview error state:
    // let errorViewModel = MyAppointmentsViewModel()
    // errorViewModel.errorMessage = "Could not connect to the server. Please check your connection."

    // To preview empty state:
    // let emptyViewModel = MyAppointmentsViewModel() // Default is empty

    return NavigationView { // Wrap preview in NavigationView if the view itself uses one
        MyAppointmentsView()
            // You can inject the dummy view model for preview using private init if needed,
            // but using @StateObject often works okay directly in previews.
            // To force a specific state, modify the viewModel directly like above.
            // .environmentObject(previewViewModel) // Only if using EnvironmentObject
    }
}
