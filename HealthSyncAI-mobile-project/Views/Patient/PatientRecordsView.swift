// HealthSyncAI-mobile-project/Views/Patient/PatientRecordsView.swift
// NEW FILE (Create a 'Patient' subfolder within Views if desired - though doctors access this too)
import SwiftUI

struct PatientRecordsView: View {
    // Use @StateObject if the view creates the VM, @ObservedObject if passed in
    @StateObject private var viewModel: PatientRecordsViewModel

    // State to control sheet presentation for creating new note
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
                Text("Error: \(error)")
                    .foregroundColor(.red)
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
            }
        }
        .navigationTitle("Patient #\(viewModel.patientId) Records")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .sheet(isPresented: $showingCreateNoteSheet) {
            // Present the CreateDoctorNoteView as a sheet
            NavigationView { // Embed in NavigationView for title/buttons inside sheet
                 CreateDoctorNoteView(patientId: viewModel.patientId) { success in
                     // This closure is called when the sheet is dismissed by the child view
                     showingCreateNoteSheet = false
                     if success {
                         viewModel.fetchRecords() // Refresh records if save was successful
                     }
                 }
            }
        }
        // No .onAppear needed here as VM fetches on init
    }
}

// MARK: - Health Record Card View (Helper)
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
                            Text("\(symptom.name)\(symptom.severity.map { " (\($0)/10)" } ?? "")\(symptom.duration.map { " - \($0)" } ?? "")")
                            if let desc = symptom.description, !desc.isEmpty {
                                Text(desc).font(.caption).foregroundColor(.gray)
                            }
                        }
                    }
                    if let diagnosis = record.diagnosis, !diagnosis.isEmpty {
                         RecordDetailSection(title: "Diagnosis", items: diagnosis) { diag in
                             Text("\(diag.name)\(diag.icd10Code.map { " (\($0))" } ?? "")")
                             if let desc = diag.description, !desc.isEmpty {
                                 Text(desc).font(.caption).foregroundColor(.gray)
                             }
                         }
                    }
                     if let plan = record.treatmentPlan, !plan.isEmpty {
                         RecordDetailSection(title: "Treatment Plan", items: plan) { p in
                             Text(p.description)
                             if let dur = p.duration, !dur.isEmpty { Text("Duration: \(dur)").font(.caption).foregroundColor(.gray) }
                             if let fu = p.followUp, !fu.isEmpty { Text("Follow-up: \(fu)").font(.caption).foregroundColor(.gray) }
                         }
                    }
                     if let meds = record.medication, !meds.isEmpty {
                         RecordDetailSection(title: "Medication", items: meds) { med in
                             Text("\(med.name) \(med.dosage), \(med.frequency)")
                              if let dur = med.duration, !dur.isEmpty { Text("Duration: \(dur)").font(.caption).foregroundColor(.gray) }
                             if let notes = med.notes, !notes.isEmpty { Text("Notes: \(notes)").font(.caption).foregroundColor(.gray) }
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
                }
                .padding(.leading) // Indent details
            }
            .font(.subheadline) // Make disclosure group header slightly smaller
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Record Detail Section Helper
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
        NavigationView {
            PatientRecordsView(patientId: 1) // Use a dummy ID for preview
        }
    }
}
