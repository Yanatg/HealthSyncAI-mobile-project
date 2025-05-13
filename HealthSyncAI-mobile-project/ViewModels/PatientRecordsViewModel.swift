
import Foundation
import Combine

@MainActor
class PatientRecordsViewModel: ObservableObject {
    @Published var healthRecords: [HealthRecord] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var patientId: Int

    private let networkManager = NetworkManager.shared

    init(patientId: Int) {
        self.patientId = patientId
        fetchRecords() // Fetch records on initialization
    }

    func fetchRecords() {
        guard patientId > 0 else {
            errorMessage = "Invalid Patient ID provided."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedRecords = try await networkManager.fetchPatientHealthRecords(patientId: patientId)
                // Sort records, newest first
                 self.healthRecords = fetchedRecords.sorted {
                     guard let date1 = ISO8601DateFormatter().date(from: $0.createdAt),
                           let date2 = ISO8601DateFormatter().date(from: $1.createdAt) else {
                         return false // Keep original order if parsing fails
                     }
                     return date1 > date2
                 }
                print("✅ Fetched \(self.healthRecords.count) records for patient \(patientId).")
            } catch let error as NetworkError {
                errorMessage = "Failed to load records: \(error.localizedDescription)"
                print("❌ NetworkError fetching records for patient \(patientId): \(error)")
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                 print("❌ Unexpected error fetching records for patient \(patientId): \(error)")
            }
            isLoading = false
        }
    }
}
