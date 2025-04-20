// HealthSyncAI-mobile-project/ViewModels/DashboardViewModel.swift
// NEW FILE

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {

    @Published var statistics: StatisticsData? = nil // Store the fetched data
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let networkManager = NetworkManager.shared
    // Optional: Inject AppState if needed for logout on auth error
    // weak var appState: AppState?

    init(/* appState: AppState? = nil */) {
       // self.appState = appState
       // Fetch when the view appears
    }

    func fetchStatistics() {
        guard !isLoading else { return } // Prevent multiple simultaneous fetches

        print("⏳ Fetching dashboard statistics...")
        isLoading = true
        errorMessage = nil
        statistics = nil // Clear old data while loading

        Task {
            do {
                let fetchedData = try await networkManager.fetchStatistics()
                self.statistics = fetchedData
                print("✅ Successfully fetched statistics.")

            } catch let error as NetworkError {
                print("❌ NetworkError fetching statistics: \(error)")
                if case .unauthorized = error {
                   // appState?.logout() // Example: Log out if token expired
                   errorMessage = "Your session may have expired. Please try logging in again."
                } else {
                   errorMessage = error.localizedDescription
                }
            } catch {
                print("❌ Unexpected error fetching statistics: \(error)")
                errorMessage = "An unexpected error occurred while fetching statistics."
            }
            isLoading = false // Ensure loading state is turned off
        }
    }
}
