// HealthSyncAI-mobile-project/HealthSyncAI_mobile_projectApp.swift
// MODIFY THE body Scene:
import SwiftUI

@main
struct HealthSyncAI_mobile_projectApp: App {
    @State private var isLoggedIn: Bool = false
    @State private var userRole: UserRole? = nil

    init() {
        if let token = KeychainHelper.standard.getAuthToken(), !token.isEmpty {
             _isLoggedIn = State(initialValue: true)
             _userRole = State(initialValue: KeychainHelper.standard.getUserRole())
             print("User is already logged in with role: \(userRole?.rawValue ?? "Unknown")")
         } else {
             print("User is not logged in.")
         }
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                // --- Navigate based on role ---
                switch userRole {
                case .patient:
                    // Replace with actual Patient View later
                    // For now, maybe show a placeholder or their records
                     NavigationView { // Wrap patient view for consistency
                         // Replace with PatientHealthRecordsView or PatientDashboard
                         Text("Patient Dashboard (Placeholder)")
                             .navigationTitle("Patient View")
                             .toolbar { // Add a logout button
                                 ToolbarItem(placement: .navigationBarLeading) {
                                     Button("Logout") { performLogout() }
                                 }
                             }
                     }
                     .onAppear { print("Showing Patient View") }

                case .doctor:
                     // *** USE THE NEW DOCTOR VIEW ***
                     // The DoctorAppointmentsView already includes a NavigationView
                     DoctorAppointmentsView()
                         .onAppear { print("Showing Doctor View") }
                         // Add logout capability within DoctorAppointmentsView or via a shared mechanism if needed

                case .none:
                     // Handle error or force logout
                     VStack {
                         Text("Error: Role not found after login.")
                         Button("Logout") { performLogout() }
                             .padding()
                     }
                }

            } else {
                // Show LoginView, passing the bindings
                LoginView(isLoggedIn: $isLoggedIn, loggedInRole: $userRole)
            }
        }
    }

    // Helper function for logout logic
    func performLogout() {
        print("Performing logout...")
        KeychainHelper.standard.clearAuthCredentials()
        isLoggedIn = false
        userRole = nil
    }
}
