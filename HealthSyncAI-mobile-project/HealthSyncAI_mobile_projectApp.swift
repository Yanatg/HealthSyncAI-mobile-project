// YourAppNameApp.swift
import SwiftUI

@main
struct HealthSyncAI_mobile_projectApp: App {
    // State to track authentication status and role
    @State private var isLoggedIn: Bool = false // Check Keychain on launch in a real app
    @State private var userRole: UserRole? = nil  // Check Keychain on launch

    init() {
        // Check keychain on app launch to see if already logged in
        if let token = KeychainHelper.standard.getAuthToken(), !token.isEmpty {
             // Basic check, ideally validate token with backend too
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
                // You would replace these with your actual views
                switch userRole {
                case .patient:
                    Text("Patient Dashboard (Health Record View)") // Replace with your Patient main view
                        .navigationTitle("Patient")
                        .onAppear { print("Showing Patient View") }
                        // Add a logout button somewhere inside this view
                case .doctor:
                     Text("Doctor Dashboard (Doctor Note View)") // Replace with your Doctor main view
                        .navigationTitle("Doctor")
                         .onAppear { print("Showing Doctor View") }
                         // Add a logout button somewhere inside this view
                case .none:
                     Text("Error: Role not found after login.")
                     // Maybe force logout here
                }

            } else {
                // Show LoginView, passing the bindings
                LoginView(isLoggedIn: $isLoggedIn, loggedInRole: $userRole)
            }
        }
    }
}
