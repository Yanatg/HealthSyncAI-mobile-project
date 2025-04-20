// HealthSyncAI-mobile-project/Views/RegistrationView.swift
import SwiftUI

struct RegistrationView: View {
    // Receive the existing AuthViewModel instance
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss // Keep dismiss

    // For DatePicker
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 1900, month: 1, day: 1)
        let end = Date() // Today
        return calendar.date(from: startComponents)! ... end
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // Title removed, handled by Navigation Title now

                // --- Role Selection (Use registerSelectedRole) ---
                Picker("Register As", selection: $viewModel.registerSelectedRole) { // Bind to register role
                    ForEach(UserRole.allCases) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)

                // --- Common Fields (Use register properties) ---
                Group {
                    TextField("Username", text: $viewModel.registerUsername) // Bind to register props
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("Email", text: $viewModel.registerEmail)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password (min 8 characters)", text: $viewModel.registerPassword)
                        .textContentType(.newPassword)

                    SecureField("Confirm Password", text: $viewModel.registerConfirmPassword)
                        .textContentType(.newPassword)

                    TextField("First Name", text: $viewModel.registerFirstName)
                        .textContentType(.givenName)

                    TextField("Last Name", text: $viewModel.registerLastName)
                        .textContentType(.familyName)
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())

                // --- Patient Specific Fields (Use register properties) ---
                if viewModel.registerSelectedRole == .patient {
                    Section(header: Text("Patient Details").font(.headline).padding(.top)) {
                        DatePicker("Date of Birth", selection: $viewModel.registerDateOfBirth, in: dateRange, displayedComponents: .date) // Bind to register prop

                        Picker("Gender", selection: $viewModel.registerSelectedGender) { // Bind to register prop
                            ForEach(Gender.allCases) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }

                        TextField("Height (cm)", text: $viewModel.registerHeightCmString) // Bind to register prop
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Weight (kg)", text: $viewModel.registerWeightKgString) // Bind to register prop
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Blood Type (e.g., A+, O-)", text: $viewModel.registerBloodType) // Bind to register prop
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Allergies (optional, comma-separated)", text: $viewModel.registerAllergies) // Bind to register prop
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Existing Conditions (optional)", text: $viewModel.registerExistingConditions) // Bind to register prop
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                // --- Doctor Specific Fields (Use register properties) ---
                if viewModel.registerSelectedRole == .doctor {
                    Section(header: Text("Doctor Details").font(.headline).padding(.top)) {
                        TextField("Specialization", text: $viewModel.registerSpecialization) // Bind to register prop
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        TextField("Qualifications (e.g., MD, Board Certified)", text: $viewModel.registerQualifications) // Bind to register prop
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Toggle("Currently Available for Appointments", isOn: $viewModel.registerIsAvailable) // Bind to register prop
                            .padding(.top, 5)
                    }
                }

                // --- Error Message ---
                if let error = viewModel.errorMessage, !viewModel.isLoading {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }

                // --- Register Button ---
                Button {
                    // Clear login fields before registration attempt (optional)
                    // viewModel.clearLoginFields()
                    viewModel.register(appState: appState)
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                             // Display the selected REGISTER role
                            Text("Register as \(viewModel.registerSelectedRole.rawValue)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(viewModel.isLoading ? Color.gray : Color.accentColor)
                    .cornerRadius(10)
                }
                 // Disable based on REGISTRATION form validity
                .disabled(viewModel.isLoading || !viewModel.isRegisterFormValid)
                .padding(.top)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Create Account") // Set navigation title here
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Clear login fields when entering registration (optional)
            // viewModel.clearLoginFields()
            // Clear any potential error message from login attempt
            viewModel.errorMessage = nil
        }
        // No need for .environmentObject(appState) here as it's passed down by NavigationView
    }
}

// Preview needs the ViewModel passed in
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Pass a dummy AuthViewModel instance
            RegistrationView(viewModel: AuthViewModel())
                .environmentObject(AppState()) // And dummy AppState
        }
    }
}
