// HealthSyncAI-mobile-project/HealthSyncAI_mobile_projectApp.swift
// No structural changes needed here, just confirming the LoginView instantiation.
import SwiftUI

@main
struct HealthSyncAI_mobile_projectApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var userRole: UserRole? = nil // This is the source state

    init() {
        if let token = KeychainHelper.standard.getAuthToken(), !token.isEmpty {
             _isLoggedIn = State(initialValue: true)
             _userRole = State(initialValue: KeychainHelper.standard.getUserRole())
             print("App Init: User is already logged in with role: \(userRole?.rawValue ?? "Unknown")")
         } else {
             print("App Init: User is not logged in.")
         }
    }

    var body: some Scene {
        WindowGroup {
            // This top-level conditional structure reacts to isLoggedIn and userRole
            if isLoggedIn {
                switch userRole {
                case .patient:
                     // Using PatientRecordsView as a placeholder for Patient dashboard
                     NavigationView {
                         // You would replace this with your actual Patient main view/dashboard
                         PatientRecordsView(patientId: KeychainHelper.standard.getUserIdAsInt() ?? 0) // Example: Pass patient ID
                             .navigationTitle("Your Health Records")
                             .toolbar {
                                 ToolbarItem(placement: .navigationBarLeading) {
                                     Button("Logout") { performLogout() }
                                 }
                             }
                     }
                     .onAppear { print("App Body: Showing Patient View") }

                case .doctor:
                     DoctorAppointmentsView() // This view includes its own NavigationView
                         .onAppear { print("App Body: Showing Doctor View") }
                         // Consider adding logout mechanism accessible from Doctor views

                case .none:
                     // This state should ideally not happen if login was successful
                     VStack {
                         Text("Error: Valid role not found after login.")
                         Button("Logout") { performLogout() }
                             .padding()
                     }
                     .onAppear { print("App Body: Error - Role is nil despite being logged in.") }
                }

            } else {
                // Show LoginView, passing the bindings correctly
                // Make sure the parameter name `userRole` matches the @Binding in LoginView
                LoginView(isLoggedIn: $isLoggedIn, userRole: $userRole)
                    .onAppear{ print("App Body: Showing Login View") }
            }
        }
    }

    // Helper function for logout logic
    func performLogout() {
        print("Performing logout...")
        KeychainHelper.standard.clearAuthCredentials()
        // Update state to trigger UI change back to LoginView
        isLoggedIn = false
        userRole = nil
    }
}
