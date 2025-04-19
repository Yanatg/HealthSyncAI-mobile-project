// HealthSyncAI-mobile-project/ViewModels/CreateDoctorNoteViewModel.swift
// NEW FILE
import Foundation
import Combine
import SwiftUI // For Binding

@MainActor
class CreateDoctorNoteViewModel: ObservableObject {
    // Form Fields
    @Published var title: String = ""
    @Published var summary: String = ""
    @Published var symptoms: [Symptom] = [Symptom(name: "")] // Start with one empty
    @Published var diagnosis: [Diagnosis] = [Diagnosis(name: "")]
    @Published var treatmentPlan: [TreatmentPlan] = [TreatmentPlan(description: "")]
    @Published var medication: [Medication] = [Medication(name: "", dosage: "", frequency: "")]

    // State Management
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var saveSuccess: Bool = false

    let patientId: Int
    private let networkManager = NetworkManager.shared

    init(patientId: Int) {
        self.patientId = patientId
    }

    // --- Dynamic Array Management ---

    func addSymptom() {
        symptoms.append(Symptom(name: ""))
    }
    func removeSymptom(at offsets: IndexSet) {
        symptoms.remove(atOffsets: offsets)
        if symptoms.isEmpty { addSymptom() } // Ensure at least one row
    }

    func addDiagnosis() {
        diagnosis.append(Diagnosis(name: ""))
    }
    func removeDiagnosis(at offsets: IndexSet) {
        diagnosis.remove(atOffsets: offsets)
        if diagnosis.isEmpty { addDiagnosis() }
    }

    func addTreatmentPlan() {
        treatmentPlan.append(TreatmentPlan(description: ""))
    }
    func removeTreatmentPlan(at offsets: IndexSet) {
        treatmentPlan.remove(atOffsets: offsets)
        if treatmentPlan.isEmpty { addTreatmentPlan() }
    }

    func addMedication() {
        medication.append(Medication(name: "", dosage: "", frequency: ""))
    }
    func removeMedication(at offsets: IndexSet) {
        medication.remove(atOffsets: offsets)
        if medication.isEmpty { addMedication() }
    }

    // --- Form Validation (Basic Example) ---
    private func validateForm() -> Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Title cannot be empty."
            return false
        }
        // Add more specific validation as needed (e.g., check required fields in dynamic lists)
        errorMessage = nil
        return true
    }

    // --- Save Action ---
    func saveNote() {
        guard validateForm() else { return }

        isLoading = true
        errorMessage = nil
        saveSuccess = false

        // Filter out empty entries before creating request body
        let nonEmptySymptoms = symptoms.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let nonEmptyDiagnosis = diagnosis.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let nonEmptyTreatment = treatmentPlan.filter { !$0.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let nonEmptyMedication = medication.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }


        let requestBody = CreateDoctorNoteRequestBody(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            patientId: patientId,
            symptoms: nonEmptySymptoms.toRequestBodies(), // Use helper extensions
            diagnosis: nonEmptyDiagnosis.toRequestBodies(),
            treatmentPlan: nonEmptyTreatment.toRequestBodies(),
            medication: nonEmptyMedication.toRequestBodies()
        )

         print("Attempting to save doctor note for patient \(patientId) with body:")
         // print(requestBody) // Be cautious logging potentially sensitive data

        Task {
            do {
                let createdRecord = try await networkManager.createDoctorNote(noteData: requestBody)
                print("✅ Doctor note saved successfully! Record ID: \(createdRecord.id)")
                saveSuccess = true
                // Optionally clear the form or trigger navigation
            } catch let error as NetworkError {
                errorMessage = "Failed to save note: \(error.localizedDescription)"
                 print("❌ NetworkError saving note: \(error)")
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print("❌ Unexpected error saving note: \(error)")
            }
            isLoading = false
        }
    }

     // --- Binding Helpers for Optional Int/Double ---
     // Needed because TextField binds to String, but model might have Int? or Double?
     func bindingForSymptomSeverity(index: Int) -> Binding<String> {
         Binding<String>(
             get: { String(self.symptoms[index].severity ?? 0) }, // Default to 0 if nil
             set: { self.symptoms[index].severity = Int($0) } // Attempt conversion, sets nil if invalid
         )
     }

     // Add similar binding helpers if needed for Diagnosis.confidence etc.
}
