// HealthSyncAI-mobile-project/Views/Doctor/CreateDoctorNoteView.swift
// NEW FILE
import SwiftUI

struct CreateDoctorNoteView: View {
    @StateObject private var viewModel: CreateDoctorNoteViewModel
    var onDismiss: (Bool) -> Void // Closure to call when dismissing (true if saved)

    @Environment(\.dismiss) private var dismiss // Environment value to dismiss the sheet

    init(patientId: Int, onDismiss: @escaping (Bool) -> Void) {
        _viewModel = StateObject(wrappedValue: CreateDoctorNoteViewModel(patientId: patientId))
        self.onDismiss = onDismiss
    }

    var body: some View {
        Form {
            // --- General Information ---
            Section("General Information") {
                TextField("Title (e.g., Follow-up Visit)", text: $viewModel.title)
                TextEditor(text: $viewModel.summary) // Use TextEditor for multi-line summary
                     .frame(height: 100) // Give it some default height
                     .overlay(
                         RoundedRectangle(cornerRadius: 5)
                             .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                     )
                 // Display Patient ID (read-only)
                 Text("Patient ID: \(viewModel.patientId)")
                     .foregroundColor(.gray)
            }

            // --- Symptoms ---
            Section("Symptoms") {
                ForEach($viewModel.symptoms) { $symptom in
                    VStack(alignment: .leading) {
                        TextField("Symptom Name", text: $symptom.name)
                        HStack {
                             Text("Severity (1-10):")
                             // Use the binding helper for Int?
                             TextField("Optional", text: viewModel.bindingForSymptomSeverity(index: viewModel.symptoms.firstIndex(where: { $0.id == symptom.id }) ?? 0))
                                 .keyboardType(.numberPad)
                                 .frame(width: 50) // Limit width
                         }
                        TextField("Duration (e.g., 3 days)", text: $symptom.duration.bound)
                        TextField("Description (optional)", text: $symptom.description.bound)
                    }
                    .padding(.vertical, 2)
                }
                .onDelete(perform: viewModel.removeSymptom) // Swipe to delete

                Button("+ Add Symptom", action: viewModel.addSymptom)
            }

            // --- Diagnosis ---
             Section("Diagnosis") {
                 ForEach($viewModel.diagnosis) { $diag in
                     VStack(alignment: .leading) {
                         TextField("Diagnosis Name", text: $diag.name)
                         TextField("ICD-10 Code (optional)", text: $diag.icd10Code.bound)
                         TextField("Description (optional)", text: $diag.description.bound)
                     }
                      .padding(.vertical, 2)
                 }
                 .onDelete(perform: viewModel.removeDiagnosis)
                 Button("+ Add Diagnosis", action: viewModel.addDiagnosis)
             }


             // --- Treatment Plan ---
             Section("Treatment Plan") {
                 ForEach($viewModel.treatmentPlan) { $plan in
                     VStack(alignment: .leading) {
                         TextField("Treatment Description", text: $plan.description)
                         TextField("Duration (optional)", text: $plan.duration.bound)
                         TextField("Follow-up (optional)", text: $plan.followUp.bound)
                     }
                      .padding(.vertical, 2)
                 }
                 .onDelete(perform: viewModel.removeTreatmentPlan)
                 Button("+ Add Treatment", action: viewModel.addTreatmentPlan)
             }


             // --- Medication ---
             Section("Medication") {
                 ForEach($viewModel.medication) { $med in
                     VStack(alignment: .leading) {
                         TextField("Medication Name", text: $med.name)
                         TextField("Dosage (e.g., 10mg)", text: $med.dosage)
                         TextField("Frequency (e.g., Once daily)", text: $med.frequency)
                         TextField("Duration (optional)", text: $med.duration.bound)
                         TextField("Notes (optional)", text: $med.notes.bound)
                     }
                     .padding(.vertical, 2)
                 }
                 .onDelete(perform: viewModel.removeMedication)
                 Button("+ Add Medication", action: viewModel.addMedication)
             }


            // --- Error Message ---
            if let error = viewModel.errorMessage {
                Section {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Create Doctor Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss() // Dismiss the sheet without saving
                    onDismiss(false) // Notify parent view (no success)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    viewModel.saveNote()
                }
                .disabled(viewModel.isLoading) // Disable save while loading
            }
        }
        .overlay { // Show loading indicator over the form
             if viewModel.isLoading {
                 Color.black.opacity(0.4)
                     .edgesIgnoringSafeArea(.all)
                 ProgressView("Saving...")
                     .progressViewStyle(CircularProgressViewStyle(tint: .white))
                     .scaleEffect(1.5)
                     .padding()
                     .background(Color.gray.opacity(0.8))
                     .cornerRadius(10)
             }
         }
        .onChange(of: viewModel.saveSuccess) { success in
             // Dismiss the sheet when save is successful
             if success {
                 dismiss()
                 onDismiss(true) // Notify parent view (success)
             }
         }
    }
}

// Helper to create a Binding for optional Strings used in TextFields
extension Optional where Wrapped == String {
    var bound: String {
        get { self ?? "" }
        set { self = newValue.isEmpty ? nil : newValue }
    }
}


struct CreateDoctorNoteView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
             CreateDoctorNoteView(patientId: 1) { _ in } // Dummy patient ID and dismiss handler
        }
    }
}
