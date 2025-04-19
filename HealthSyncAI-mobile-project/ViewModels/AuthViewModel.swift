// HealthSyncAI-mobile-project/ViewModels/AuthViewModel.swift
// NO CHANGES NEEDED for role-based redirection logic compared to the previous version.
// It already sets loggedInUserRole based on selectedRole on success.
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var selectedRole: UserRole = .patient // Role selected in the UI
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var isAuthenticated: Bool = false      // Triggers UI change in LoginView
    @Published var loggedInUserRole: UserRole? = nil // Set on successful login

    private let networkManager = NetworkManager.shared
    private let keychainHelper = KeychainHelper.standard

    func login() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and Password cannot be empty."
            return
        }
        print("Attempting login with Username: \(username), Role: \(selectedRole.rawValue)")

        isLoading = true
        errorMessage = nil
        isAuthenticated = false // Reset state before attempt
        loggedInUserRole = nil  // Reset state before attempt

        // Capture selected role *before* async task
        let roleToLoginAs = selectedRole

        Task {
            do {
                let loginCredentials = LoginRequestBody(username: username, password: password)
                let authResponse: AuthResponse = try await networkManager.login(credentials: loginCredentials)

                // --- Success ---
                print("✅ Login successful!")
                keychainHelper.saveAuthToken(authResponse.accessToken)
                let userIdString = String(authResponse.userId)
                keychainHelper.saveUserId(userIdString)
                // ** Save the role that was selected during this login attempt **
                keychainHelper.saveUserRole(roleToLoginAs)

                // ** Update the ViewModel's state **
                // This will be picked up by LoginView's .onChange
                self.loggedInUserRole = roleToLoginAs
                self.isAuthenticated = true
                self.password = "" // Clear password field

            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
                print("❌ Login Network Error: \(error.localizedDescription)")
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print("❌ Login Failed: \(error)")
            }
            // Ensure isLoading is set to false regardless of outcome
            self.isLoading = false
        }
    }
}
