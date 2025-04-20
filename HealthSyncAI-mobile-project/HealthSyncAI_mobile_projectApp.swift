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
                    TabView { // <<< START TabView
                        // Records Tab
                        NavigationView {
                            PatientRecordsView(patientId: appState.userId ?? 0)
                        }
                        .tabItem {
                            Label(
                                "Records",
                                systemImage: "list.bullet.clipboard.fill"
                            )
                        }
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
                            MyAppointmentsView()
                        }
                        .tabItem {
                            Label("Appointments", systemImage: "calendar")
                        }
                        .environmentObject(appState)

                        // --- UPDATED: Dashboard Tab ---
                        NavigationView {
                            // Use the new DashboardView
                            DashboardView()
                        }
                        .tabItem { // <<< START .tabItem closure
                            Label(
                                "Dashboard",
                                systemImage: "square.grid.2x2.fill" // Or "chart.pie.fill"
                            )
                            // --- REMOVE EXTRA BRACE HERE ---
                        } // <<< END .tabItem closure
                        .environmentObject(appState) // Apply environment object after .tabItem

                        // --- REMOVE EXTRA BRACE HERE ---

                    } // <<< END TabView
                    .onAppear {
                        print(
                            "App Body: Showing Patient TabView (User ID: \(appState.userId ?? 0))"
                        )
                    }

                case .doctor:
                    // Doctor view remains the same for now
                    DoctorAppointmentsView()
                        .environmentObject(appState)
                        .onAppear {
                            print(
                                "App Body: Showing Doctor View (User ID: \(appState.userId ?? 0))"
                            )
                        }

                case .none:
                    // Fallback if logged in but role is somehow nil
                    VStack {
                        Text("Error: User logged in but role is missing.")
                        Button("Logout") { appState.logout() }
                            .padding()
                    }
                    .onAppear {
                        print(
                            "App Body: Error - Role is nil despite being logged in."
                        )
                    }
                }

            } else {
                // Show LoginView, passing AppState
                LoginView()
                    .environmentObject(appState)
                    .onAppear { print("App Body: Showing Login View") }
            }
        }
    }
}
