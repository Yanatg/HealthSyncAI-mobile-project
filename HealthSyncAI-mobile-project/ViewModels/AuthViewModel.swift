// ViewModels/AuthViewModel.swift
import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var selectedRole: UserRole = .patient
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var loggedInUserRole: UserRole? = nil

    private let networkManager = NetworkManager.shared
    private let keychainHelper = KeychainHelper.standard

    func login() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and Password cannot be empty."
            return
        }
        print("Attempting login with Username: \(username), Password: [REDACTED]") // Don't log password directly

        isLoading = true
        errorMessage = nil
        isAuthenticated = false
        loggedInUserRole = nil

        Task {
            do {
                // Prepare the credentials object (NetworkManager's login function needs this)
                let loginCredentials = LoginRequestBody(username: username, password: password)

                // Call the NetworkManager's login function.
                // This function NOW internally handles sending as multipart/form-data.
                let authResponse: AuthResponse = try await networkManager.login(credentials: loginCredentials)

                // --- Success (This part remains the same) ---
                print("✅ Login successful!")
                keychainHelper.saveAuthToken(authResponse.accessToken)
                let userIdString = String(authResponse.userId)
                keychainHelper.saveUserId(userIdString)
                keychainHelper.saveUserRole(selectedRole)

                loggedInUserRole = selectedRole
                isAuthenticated = true
                password = "" // Clear password field

            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
                print("❌ Login Network Error: \(error.localizedDescription)")
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                print("❌ Login Failed: \(error)")
            }
            isLoading = false
        }
    }
}
