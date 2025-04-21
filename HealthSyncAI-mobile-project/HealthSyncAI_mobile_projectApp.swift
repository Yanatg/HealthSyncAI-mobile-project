// HealthSyncAI-mobile-project/HealthSyncAI_mobile_projectApp.swift
// UPDATED FILE
import SwiftUI

@main
struct HealthSyncAI_mobile_projectApp: App {
    @StateObject private var appState = AppState()
    // --- ADDED: State for splash screen visibility ---
    @State private var showSplashScreen = true

    var body: some Scene {
        WindowGroup {
            // --- UPDATED: Main content switching ---
            ZStack { // Use ZStack to layer splash over content potentially
                // --- Splash Screen Logic ---
                if showSplashScreen {
                    SplashScreenView()
                        .transition(.opacity) // Fade transition
                        .onAppear {
                            // Hide splash screen after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Adjust delay (e.g., 2.0 seconds)
                                withAnimation { // Animate the transition
                                    showSplashScreen = false
                                }
                            }
                        }
                } else {
                    // --- Existing Main Content Logic ---
                    // View hierarchy now depends on appState
                    if appState.isLoggedIn {
                        switch appState.userRole {
                        case .patient:
                            // Patient TabView
                            patientTabView
                                .environmentObject(appState) // Pass state down
                                .transition(.opacity) // Fade in main content

                        case .doctor:
                            // Doctor view
                            DoctorAppointmentsView()
                                .environmentObject(appState)
                                .transition(.opacity) // Fade in main content
                                .onAppear { print("App Body: Showing Doctor View (User ID: \(appState.userId ?? 0))") }

                        case .none:
                            // Fallback error view
                            errorView
                                .transition(.opacity) // Fade in main content
                        }
                    } else {
                        // Show LoginView
                        LoginView()
                            .environmentObject(appState)
                            .transition(.opacity) // Fade in main content
                            .onAppear { print("App Body: Showing Login View") }
                    }
                    // --- End Existing Main Content Logic ---
                }
            }
            // --- End Main content switching ---
        }
    }

    // --- Extracted Patient TabView for clarity ---
    private var patientTabView: some View {
        TabView {
            // Records Tab
            NavigationView { PatientRecordsView(patientId: appState.userId ?? 0) }
                .tabItem { Label("Records", systemImage: "list.bullet.clipboard.fill") }


            // Chat Tab
            NavigationView { ChatView(appState: appState) }
                .tabItem { Label("Chat", systemImage: "message.fill") }

            // Appointments Tab
            NavigationView { MyAppointmentsView() }
                .tabItem { Label("Appointments", systemImage: "calendar") }


            // Dashboard Tab
            NavigationView { DashboardView() }
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2.fill") }

        }
        .onAppear { print("App Body: Showing Patient TabView (User ID: \(appState.userId ?? 0))") }
        // EnvironmentObject is applied below the switch case now, or individually if needed
    }

    // --- Extracted Error View for clarity ---
    private var errorView: some View {
        VStack {
            Text("Error: User logged in but role is missing.")
            Button("Logout") { appState.logout() }
                .padding()
        }
        .onAppear { print("App Body: Error - Role is nil despite being logged in.") }
    }
}

// Make sure placeholder views exist if you haven't implemented them fully yet
// struct DoctorAppointmentsView: View { var body: some View { Text("Doctor View Placeholder") } }
// struct LoginView: View { var body: some View { Text("Login View Placeholder") } }
// PatientRecordsView, ChatView, MyAppointmentsView, DashboardView should exist as defined previously
