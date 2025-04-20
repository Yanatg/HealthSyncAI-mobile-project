// HealthSyncAI-mobile-project/HealthSyncAI_mobile_projectApp.swift
// UPDATED FILE
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
                    // --- Use TabView for Patient ---
                    TabView {
                        // Records Tab
                        NavigationView {
                            PatientRecordsView(patientId: appState.userId ?? 0)
                        }
                        .tabItem { Label("Records", systemImage: "list.bullet.clipboard.fill") }
                        .environmentObject(appState)

                        // Chat Tab
                        NavigationView {
                            ChatView(appState: appState)
                        }
                        .tabItem { Label("Chat", systemImage: "message.fill") }
                        // No need for separate .environmentObject here, ChatView init receives it

                        // Appointments Tab
                        NavigationView {
                            // Use the actual Patient Appointments View
                            MyAppointmentsView() // <<< Displays the list of patient's appointments
                        }
                         .tabItem { Label("Appointments", systemImage: "calendar") }
                         .environmentObject(appState) // Pass state down if needed by view/viewmodel


                        // Settings/Logout Tab
                        NavigationView {
                             VStack(spacing: 20) {
                                 Text("User ID: \(appState.userId ?? 0)")
                                 Text("Role: \(appState.userRole?.rawValue ?? "Unknown")")
                                 Spacer()
                                 Button("Logout") { appState.logout() }
                                     .buttonStyle(.borderedProminent)
                                     .tint(.red)
                                 Spacer()
                             }
                            .navigationTitle("Settings")
                        }
                         .tabItem { Label("Settings", systemImage: "gear") }
                         .environmentObject(appState)

                    }
                    .onAppear { print("App Body: Showing Patient TabView (User ID: \(appState.userId ?? 0))") }


                case .doctor:
                    // Doctor view remains the same for now
                    DoctorAppointmentsView()
                        .environmentObject(appState)
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
                     .environmentObject(appState)
                    .onAppear{ print("App Body: Showing Login View") }
            }
        }
    }
}
