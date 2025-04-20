// HealthSyncAI-mobile-project/HealthSyncAI_mobile_projectApp.swift
import SwiftUI

@main
struct HealthSyncAI_mobile_projectApp: App {
    // Use AppState as the single source of truth for auth state
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            // View hierarchy now depends on appState
            if appState.isLoggedIn {
                switch appState.userRole {
                case .patient:
                    // Example Patient View
                    NavigationView {
                        // Replace with your actual Patient Dashboard/View
                        PatientRecordsView(patientId: appState.userId ?? 0) // Use ID from appState
                            .navigationTitle("Your Health Records")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    // Logout button for Patient View
                                    Button("Logout") { appState.logout() }
                                        .tint(.red) // Make logout more visible
                                }
                            }
                    }
                    .onAppear { print("App Body: Showing Patient View (User ID: \(appState.userId ?? 0))") }
                    // Inject AppState for potential deeper navigation logout needs
                    .environmentObject(appState)

                case .doctor:
                    // Doctor view now needs access to AppState for logout
                    DoctorAppointmentsView()
                        .environmentObject(appState) // Inject AppState
                        .onAppear { print("App Body: Showing Doctor View (User ID: \(appState.userId ?? 0))") }

                case .none:
                    // Fallback if logged in but role is somehow nil
                    VStack {
                        Text("Error: User logged in but role is missing.")
                        Button("Logout") { appState.logout() }
                            .padding()
                    }
                    .onAppear { print("App Body: Error - Role is nil despite being logged in.") }
                }

            } else {
                // Show LoginView, passing AppState
                LoginView()
                     .environmentObject(appState) // Inject AppState
                    .onAppear{ print("App Body: Showing Login View") }
            }
        }
    }
}
