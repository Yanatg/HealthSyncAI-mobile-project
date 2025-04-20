// HealthSyncAI-mobile-project/Views/Patient/PatientRecordsView.swift
// UPDATED FILE
import SwiftUI

struct PatientRecordsView: View {
    // Use @StateObject if the view creates the VM, @ObservedObject if passed in
    @StateObject private var viewModel: PatientRecordsViewModel

    // --- ADDED: Access AppState to check user role ---
    @EnvironmentObject private var appState: AppState

    // --- ADDED: State to control sheet presentation ---
    @State private var showingCreateNoteSheet = false

    // Initialize with patientId
    init(patientId: Int) {
        _viewModel = StateObject(wrappedValue: PatientRecordsViewModel(patientId: patientId))
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Records...")
                    .padding()
            } else if let error = viewModel.errorMessage {
                VStack { // Wrap error message for better layout
                    Text("Error Loading Records")
                        .font(.headline)
                        .padding(.bottom, 2)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        viewModel.fetchRecords()
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)
                }
                .padding()
            } else if viewModel.healthRecords.isEmpty {
                Text("No health records found for this patient.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.healthRecords) { record in
                        HealthRecordCard(record: record)
                    }
                }
                .listStyle(.plain)
                // --- ADDED: Refreshable ---
                .refreshable {
                    viewModel.fetchRecords()
                }
            }
        }
        .navigationTitle("Patient #\(viewModel.patientId) Records")
        .navigationBarTitleDisplayMode(.inline)
        // --- UPDATED: Conditional Toolbar Item for "New Note" ---
        .toolbar {
            // Only show the 'New Note' button if the logged-in user is a doctor
            if appState.userRole == .doctor {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateNoteSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                        Text("New Note")
                    }
                    .disabled(viewModel.isLoading) // Disable while loading initial records
                }
            }
            // Add other toolbar items if needed (e.g., refresh, filter)
        }
        // --- ADDED: Sheet presentation for creating a new note ---
        .sheet(isPresented: $showingCreateNoteSheet) {
            // Present the CreateDoctorNoteView as a sheet
            // Embed in NavigationView for title/buttons inside the sheet
            NavigationView {
                 CreateDoctorNoteView(patientId: viewModel.patientId) { success in
                     // This closure is called when the sheet is dismissed by the child view
                     showingCreateNoteSheet = false // Ensure sheet dismisses
                     if success {
                         // Refresh records if save was successful
                         viewModel.fetchRecords()
                     }
                 }
            }
            // Prevent interactive dismissal if needed while saving, etc.
            // .interactiveDismissDisabled(viewModel.isSaving) // Assuming viewModel has such a state
        }
        // No .onAppear needed here as VM fetches on init
    }
}

// MARK: - Health Record Card View (Helper - No Changes Needed)
struct HealthRecordCard: View {
    let record: HealthRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(record.formattedRecordType)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }

            Text(record.summary)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3) // Limit summary lines

            // Display Triage Recommendation if available
            if let triage = record.triageRecommendation {
                HStack(alignment: .top) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading) {
                         Text("Triage:")
                             .font(.caption.weight(.semibold))
                         Text(triage.replacingOccurrences(of: "_", with: " ").capitalized)
                         + Text(record.formattedConfidence.map { " (\($0))" } ?? "")
                             .font(.caption)
                    }
                }
                .padding(5)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(5)
            }


            // Expandable Details Section (Example using DisclosureGroup)
            DisclosureGroup("Details") {
                VStack(alignment: .leading, spacing: 10) {
                    if let symptoms = record.symptoms, !symptoms.isEmpty {
                        RecordDetailSection(title: "Symptoms", items: symptoms) { symptom in
                            VStack(alignment: .leading, spacing: 2) { // Wrap content for alignment
                                Text("\(symptom.name)\(symptom.severity.map { " (\($0)/10)" } ?? "")\(symptom.duration.map { " - \($0)" } ?? "")")
                                if let desc = symptom.description, !desc.isEmpty {
                                    Text(desc).font(.caption).foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    if let diagnosis = record.diagnosis, !diagnosis.isEmpty {
                         RecordDetailSection(title: "Diagnosis", items: diagnosis) { diag in
                             VStack(alignment: .leading, spacing: 2) {
                                 Text("\(diag.name)\(diag.icd10Code.map { " (\($0))" } ?? "")")
                                 if let desc = diag.description, !desc.isEmpty {
                                     Text(desc).font(.caption).foregroundColor(.gray)
                                 }
                             }
                         }
                    }
                     if let plan = record.treatmentPlan, !plan.isEmpty {
                         RecordDetailSection(title: "Treatment Plan", items: plan) { p in
                             VStack(alignment: .leading, spacing: 2) {
                                 Text(p.description)
                                 if let dur = p.duration, !dur.isEmpty { Text("Duration: \(dur)").font(.caption).foregroundColor(.gray) }
                                 if let fu = p.followUp, !fu.isEmpty { Text("Follow-up: \(fu)").font(.caption).foregroundColor(.gray) }
                            }
                         }
                    }
                     if let meds = record.medication, !meds.isEmpty {
                         RecordDetailSection(title: "Medication", items: meds) { med in
                             VStack(alignment: .leading, spacing: 2) {
                                 Text("\(med.name) \(med.dosage), \(med.frequency)")
                                  if let dur = med.duration, !dur.isEmpty { Text("Duration: \(dur)").font(.caption).foregroundColor(.gray) }
                                 if let notes = med.notes, !notes.isEmpty { Text("Notes: \(notes)").font(.caption).foregroundColor(.gray) }
                            }
                         }
                    }
                    Spacer(minLength: 5)
                    Text("Created: \(record.formattedCreatedAt)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                     if record.createdAt != record.updatedAt {
                         Text("Updated: \(record.formattedUpdatedAt)")
                             .font(.caption2)
                             .foregroundColor(.gray)
                     }
                     // Display Doctor ID
                     Text("Doctor ID: \(record.doctorId)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.leading) // Indent details
            }
            .font(.subheadline) // Make disclosure group header slightly smaller
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Record Detail Section Helper (No Changes Needed)
struct RecordDetailSection<Item: Identifiable, Content: View>: View {
    let title: String
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.subheadline.weight(.semibold))
            ForEach(items) { item in
                content(item)
                    .padding(.bottom, 2)
            }
        }
    }
}


// MARK: - Preview
struct PatientRecordsView_Previews: PreviewProvider {
    static var previews: some View {
        // --- Preview as Doctor ---
        NavigationView {
            PatientRecordsView(patientId: 1) // Use a dummy ID for preview
                .environmentObject(previewAppState(role: .doctor)) // Inject Doctor role
        }
        .previewDisplayName("Doctor View")

        // --- Preview as Patient ---
        NavigationView {
            PatientRecordsView(patientId: 2) // Use a dummy ID for preview
                .environmentObject(previewAppState(role: .patient)) // Inject Patient role
        }
        .previewDisplayName("Patient View")
    }

    // Helper function to create AppState for previews
    static func previewAppState(role: UserRole) -> AppState {
        let state = AppState()
        state.isLoggedIn = true
        state.userRole = role
        state.userId = (role == .doctor) ? 101 : 2 // Example user IDs
        // Note: Previews don't interact with Keychain
        return state
    }
}
