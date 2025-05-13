import Foundation
import Combine
import SwiftUI // For Date

@MainActor
class AuthViewModel: ObservableObject {

    // --- Login Fields ---
    @Published var loginUsername: String = "" // Renamed to avoid conflict
    @Published var loginPassword: String = "" // Renamed to avoid conflict
    @Published var selectedLoginRole: UserRole = .patient // Renamed

    // --- Registration Fields ---
    @Published var registerUsername: String = ""
    @Published var registerEmail: String = ""
    @Published var registerPassword = ""
    @Published var registerConfirmPassword = ""
    @Published var registerFirstName: String = ""
    @Published var registerLastName: String = ""
    @Published var registerSelectedRole: UserRole = .patient // Separate role for registration form

    // Patient Registration Fields
    @Published var registerDateOfBirth = Date()
    @Published var registerSelectedGender: Gender = .preferNotToSay
    @Published var registerHeightCmString: String = ""
    @Published var registerWeightKgString: String = ""
    @Published var registerBloodType: String = ""
    @Published var registerAllergies: String = ""
    @Published var registerExistingConditions: String = ""

    // Doctor Registration Fields
    @Published var registerSpecialization: String = ""
    @Published var registerQualifications: String = ""
    @Published var registerIsAvailable: Bool = true

    // --- Common State Management ---
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    private let networkManager = NetworkManager.shared
    private let keychainHelper = KeychainHelper.standard

    // MARK: - Login Logic
    func login(appState: AppState) {
        // Use login-specific properties
        guard !loginUsername.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "Username and Password cannot be empty."
            return
        }
        print("Attempting login with Username: \(loginUsername), Role: \(selectedLoginRole.rawValue)")

        isLoading = true
        errorMessage = nil
        let roleToLoginAs = selectedLoginRole // Capture role before async task

        Task {
            do {
                // Use login-specific properties
                let loginCredentials = LoginRequestBody(username: loginUsername, password: loginPassword)
                let authResponse: AuthResponse = try await networkManager.login(credentials: loginCredentials)

                // --- Success: Save to Keychain FIRST ---
                print("✅ Login successful!")
                keychainHelper.saveAuthToken(authResponse.accessToken)
                // --- FIX: Pass Int directly ---
                keychainHelper.saveUserId(authResponse.userId)
                // --- END FIX ---
                keychainHelper.saveUserRole(roleToLoginAs) // Save the role used for login
                keychainHelper.saveUsername(loginUsername) // Save the username used for login

                // --- Update AppState ---
                appState.login(role: roleToLoginAs, userId: authResponse.userId)

                // Clear ONLY login password field
                self.loginPassword = ""

            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
                print("❌ Login Network Error: \(error.localizedDescription)")
            } catch {
                errorMessage = "An unexpected error occurred during login: \(error.localizedDescription)"
                print("❌ Login Failed: \(error)")
            }
            self.isLoading = false
        }
    }

    // MARK: - Registration Logic

    // --- Validation Computed Properties (For Registration) ---
    var isRegisterPasswordValid: Bool {
        registerPassword.count >= 8
    }

    var registerPasswordsMatch: Bool {
        !registerPassword.isEmpty && registerPassword == registerConfirmPassword
    }

    var isRegisterPatientFormValid: Bool {
        !registerUsername.isEmpty && !registerEmail.isEmpty && isRegisterPasswordValid && registerPasswordsMatch &&
        !registerFirstName.isEmpty && !registerLastName.isEmpty &&
        !registerHeightCmString.isEmpty && Double(registerHeightCmString) != nil &&
        !registerWeightKgString.isEmpty && Double(registerWeightKgString) != nil &&
        !registerBloodType.isEmpty
    }

     var isRegisterDoctorFormValid: Bool {
        !registerUsername.isEmpty && !registerEmail.isEmpty && isRegisterPasswordValid && registerPasswordsMatch &&
        !registerFirstName.isEmpty && !registerLastName.isEmpty &&
        !registerSpecialization.isEmpty && !registerQualifications.isEmpty
    }

    var isRegisterFormValid: Bool {
        registerSelectedRole == .patient ? isRegisterPatientFormValid : isRegisterDoctorFormValid
    }

    // --- Registration Action ---
    func register(appState: AppState) {
            guard isRegisterFormValid else {
                // ... (Error message setting remains the same)
                if !isRegisterPasswordValid { errorMessage = "Password must be at least 8 characters long." }
                else if !registerPasswordsMatch { errorMessage = "Passwords do not match." }
                else if registerSelectedRole == .patient && (Double(registerHeightCmString) == nil || Double(registerWeightKgString) == nil) {
                     errorMessage = "Please enter valid numbers for height and weight."
                }
                else { errorMessage = "Please fill in all required fields correctly." }
                return
            }

            isLoading = true
            errorMessage = nil

            let registrationData: RegistrationData
            let roleToRegisterAs = registerSelectedRole // Capture role
            let usernameToRegister = registerUsername.trimmingCharacters(in: .whitespaces) // Capture username

            // --- Use FLAT structure initializers ---
            if roleToRegisterAs == .patient {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd" // Ensure API expects this format
                let dobString = dateFormatter.string(from: registerDateOfBirth)

                let patientData = PatientRegistrationData( // Use the flat initializer
                    username: usernameToRegister, // Use captured username
                    email: registerEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: registerPassword,
                    firstName: registerFirstName.trimmingCharacters(in: .whitespaces),
                    lastName: registerLastName.trimmingCharacters(in: .whitespaces),
                    dateOfBirth: dobString,
                    gender: registerSelectedGender.backendValue, // USE backendValue
                    heightCm: Double(registerHeightCmString) ?? 0.0,
                    weightKg: Double(registerWeightKgString) ?? 0.0,
                    bloodType: registerBloodType.trimmingCharacters(in: .whitespaces),
                    allergies: registerAllergies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : registerAllergies.trimmingCharacters(in: .whitespacesAndNewlines),
                    existingConditions: registerExistingConditions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : registerExistingConditions.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                registrationData = .patient(patientData)
            } else {
                let doctorData = DoctorRegistrationData( // Use the flat initializer
                    username: usernameToRegister, // Use captured username
                    email: registerEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: registerPassword,
                    firstName: registerFirstName.trimmingCharacters(in: .whitespaces),
                    lastName: registerLastName.trimmingCharacters(in: .whitespaces),
                    // role is set automatically in the Doctor struct
                    specialization: registerSpecialization.trimmingCharacters(in: .whitespaces),
                    qualifications: registerQualifications.trimmingCharacters(in: .whitespaces),
                    isAvailable: registerIsAvailable
                )
                registrationData = .doctor(doctorData)
            }

        Task {
                    do {
                        // encodeToJson() in RegistrationData now uses the struct's custom encoder
                        let authResponse = try await networkManager.registerUser(data: registrationData)
                        print("✅ Registration successful!")

                        // --- Auto-Login after registration ---
                        keychainHelper.saveAuthToken(authResponse.accessToken)
                        // --- FIX: Pass Int directly ---
                        keychainHelper.saveUserId(authResponse.userId)
                        // --- END FIX ---
                        keychainHelper.saveUserRole(roleToRegisterAs)
                        keychainHelper.saveUsername(usernameToRegister) // Save the username used for registration

                        appState.login(role: roleToRegisterAs, userId: authResponse.userId)
                        self.registerPassword = ""
                        self.registerConfirmPassword = ""

                    } catch let error as NetworkError {
                        errorMessage = error.localizedDescription
                        print("❌ Registration Network Error: \(error.localizedDescription)")
                        print("--- Underlying Registration Error: \(error)")
                    } catch {
                        errorMessage = "An unexpected error occurred during registration: \(error.localizedDescription)" // Use localizedDescription
                        print("❌ Registration Failed: \(error)")
                    }
                    self.isLoading = false
                }
            }

    // MARK: - Helper Methods (Optional)
    func clearLoginFields() {
        loginUsername = ""
        loginPassword = ""
        errorMessage = nil // Clear error when clearing fields
    }

    func clearRegistrationFields() {
        registerUsername = ""
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        registerFirstName = ""
        registerLastName = ""
        registerDateOfBirth = Date()
        registerSelectedGender = .preferNotToSay
        registerHeightCmString = ""
        registerWeightKgString = ""
        registerBloodType = ""
        registerAllergies = ""
        registerExistingConditions = ""
        registerSpecialization = ""
        registerQualifications = ""
        registerIsAvailable = true
        errorMessage = nil // Clear error when clearing fields
    }
}
