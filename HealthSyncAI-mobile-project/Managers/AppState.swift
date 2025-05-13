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

#if DEBUG // Only compile this helper for Debug builds (used by Previews)
extension AppState {
    /// Creates a pre-configured AppState instance suitable for SwiftUI Previews.
    /// - Parameter role: The desired UserRole for the preview state.
    /// - Returns: An AppState object configured for the specified role.
    static func previewAppState(role: UserRole) -> AppState {
        let state = AppState()
        state.isLoggedIn = true // Assume logged in for most previews needing roles
        state.userRole = role
        // Assign some consistent dummy IDs based on role for predictability
        state.userId = (role == .doctor) ? 999 : 111
        // Note: This doesn't interact with Keychain. If previewed ViewModels
        // rely heavily on Keychain data fetched via AppState on init,
        // you might need more sophisticated preview setup or mocking.
        return state
    }
}
#endif
// --- END EXTENSION ---
