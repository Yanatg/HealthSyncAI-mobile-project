// HealthSyncAI-mobile-project/Managers/AppState.swift (or ViewModels)
// NEW FILE
import Foundation
import Combine

@MainActor // Ensure changes happen on the main thread for UI updates
class AppState: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var userRole: UserRole?
    @Published var userId: Int? // Store user ID if needed globally

    private let keychainHelper = KeychainHelper.standard

    init() {
        // Check Keychain for existing session on app launch
        if let token = keychainHelper.getAuthToken(), !token.isEmpty {
            self.isLoggedIn = true
            self.userRole = keychainHelper.getUserRole()
            self.userId = keychainHelper.getUserIdAsInt()
            print("AppState Init: User is logged in. Role: \(userRole?.rawValue ?? "Unknown"), ID: \(userId ?? 0)")
        } else {
            self.isLoggedIn = false
            self.userRole = nil
            self.userId = nil
            print("AppState Init: User is not logged in.")
        }
    }

    // Function called upon successful login
    func login(role: UserRole, userId: Int) {
        // Keychain saving should happen *before* this in AuthViewModel or LoginView logic
        self.isLoggedIn = true
        self.userRole = role
        self.userId = userId
        print("AppState: Login state updated. Role: \(role.rawValue), ID: \(userId)")
    }

    // Function called on logout
    func logout() {
        print("AppState: Performing logout...")
        keychainHelper.clearAuthCredentials()
        self.isLoggedIn = false
        self.userRole = nil
        self.userId = nil
    }
}
