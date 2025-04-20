// HealthSyncAI-mobile-project/Views/Patient/DashboardView.swift
// UPDATED FILE

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var appState: AppState // <<< ADD THIS

    // Define grid layout: Adaptive columns, minimum width 150
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 150), spacing: 15)
    ]

    var body: some View {
        // The NavigationView is provided by the TabView setup in App file
        content // Use the computed property for the main view structure
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            // --- Add Toolbar ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log out") {
                        appState.logout() // Call logout on the shared state
                    }
                    .tint(.red) // Style the button red
                }
            }
            // --- End Toolbar ---
            .onAppear {
                // Fetch data when the view appears
                viewModel.fetchStatistics()
            }
            // Add pull-to-refresh
            .refreshable {
                viewModel.fetchStatistics()
            }
    }

    // Main content view builder (No changes needed inside here for the button)
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading Dashboard...")
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Center it
        } else if let errorMessage = viewModel.errorMessage {
            VStack(spacing: 15) { // Error View
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange).font(.largeTitle)
                Text("Error Loading Dashboard").font(.headline)
                Text(errorMessage).font(.callout).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
                Button("Retry") { viewModel.fetchStatistics() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let stats = viewModel.statistics {
            // Display the statistics in a ScrollView with LazyVGrid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    StatisticCardView(value: stats.totalAppointments, label: "Appointments", iconName: "calendar", color: .blue)
                    StatisticCardView(value: stats.totalChatSessions, label: "Chat Sessions", iconName: "message.fill", color: .green)
                    StatisticCardView(value: stats.totalHealthRecords, label: "Health Records", iconName: "list.bullet.clipboard.fill", color: .purple)
                    StatisticCardView(value: stats.totalTriageRecords, label: "Triage Records", iconName: "heart.text.square.fill", color: .orange)
                    StatisticCardView(value: stats.totalDoctorNotes, label: "Doctor Notes", iconName: "pencil.and.scribble", color: .cyan)
                    StatisticCardView(value: stats.totalDoctors, label: "Doctors", iconName: "stethoscope", color: .teal)
                    // Add more cards as needed
                }
                .padding() // Add padding around the grid
            }
        } else {
            // Fallback if stats are nil but not loading and no error
            Text("No statistics available.")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Reusable Statistic Card View (Keep As Is)
struct StatisticCardView: View {
    let value: Int
    let label: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }

            Text("\(value)")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    // --- REMOVE THESE UNUSED LINES ---
    // let previewViewModel = DashboardViewModel()
    // previewViewModel.statistics = StatisticsData(...)
    // --- END REMOVAL ---

    // Directly create the view hierarchy for the preview
    NavigationView {
        DashboardView()
            // The DashboardView created here will initialize its own @StateObject ViewModel.
            // To preview specific data states, you'd need to inject a configured
            // ViewModel, perhaps via an initializer or by modifying the VM after creation.
            .environmentObject(AppState.previewAppState(role: UserRole.patient))
    }
}
