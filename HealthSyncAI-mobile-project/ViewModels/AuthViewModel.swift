// HealthSyncAI-mobile-project/ViewModels/AuthViewModel.swift
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var selectedRole: UserRole = .patient // Role selected in the UI
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    // REMOVE: @Published var isAuthenticated: Bool = false
    // REMOVE: @Published var loggedInUserRole: UserRole? = nil

    private let networkManager = NetworkManager.shared
    private let keychainHelper = KeychainHelper.standard

    // Function now takes AppState to update it directly
    func login(appState: AppState) {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and Password cannot be empty."
            return
        }
        print("Attempting login with Username: \(username), Role: \(selectedRole.rawValue)")

        isLoading = true
        errorMessage = nil
        // REMOVE: isAuthenticated = false
        // REMOVE: loggedInUserRole = nil

        let roleToLoginAs = selectedRole // Capture role before async task

        Task {
            do {
                let loginCredentials = LoginRequestBody(username: username, password: password)
                let authResponse: AuthResponse = try await networkManager.login(credentials: loginCredentials)

                // --- Success: Save to Keychain FIRST ---
                print("✅ Login successful!")
                keychainHelper.saveAuthToken(authResponse.accessToken)
                let userIdString = String(authResponse.userId)
                keychainHelper.saveUserId(userIdString)
                keychainHelper.saveUserRole(roleToLoginAs) // Save the role used for login

                // --- Update AppState ---
                appState.login(role: roleToLoginAs, userId: authResponse.userId) // Update the central state

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
