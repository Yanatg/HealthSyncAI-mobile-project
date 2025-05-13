import Foundation
import Security

class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

    // --- Make constants internal or public ---
    // Changed from private to internal (default)
    static let authService = "com.yourapp.auth" // Use your bundle ID or a unique name
    static let tokenAccount = "userToken"
    static let userIdAccount = "userId"
    static let userRoleAccount = "userRole"
    static let usernameAccount = "username" // Add account key for username/first name

    // Generic function to save data
    func save(_ data: Data, service: String, account: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ] as CFDictionary

        // Delete existing item first
        SecItemDelete(query)

        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
             print("Keychain save error: \(status)")
        }
        return status == errSecSuccess
    }

    // Helper to save Codable types (like AuthResponse or just the token string)
    func save<T: Codable>(_ item: T, service: String, account: String) -> Bool {
        do {
            let data = try JSONEncoder().encode(item)
            return save(data, service: service, account: account)
        } catch {
            assertionFailure("Fail to encode item for keychain: \(error)")
            return false
        }
    }

    // Generic function to read data
    func readData(service: String, account: String) -> Data? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
             // This is normal if the item hasn't been saved yet, no need to print an error here usually.
             // print("Keychain item not found for service: \(service), account: \(account)")
            return nil
        } else {
            print("Keychain read error: \(status)")
            return nil
        }
    }

    // Helper to read Codable types
    func read<T: Decodable>(service: String, account: String, type: T.Type) -> T? {
        guard let data = readData(service: service, account: account) else {
            return nil
        }
        do {
            let item = try JSONDecoder().decode(type, from: data)
            return item
        } catch {
            assertionFailure("Fail to decode item for keychain: \(error)")
            return nil
        }
    }

    // Function to delete an item
    func delete(service: String, account: String) -> Bool {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary

        let status = SecItemDelete(query)
         if status != errSecSuccess && status != errSecItemNotFound {
              print("Keychain delete error: \(status)")
         }
        return status == errSecSuccess || status == errSecItemNotFound // Consider not found as success for delete
    }

    // --- Convenience Methods for Your App ---

    func saveAuthToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        if save(data, service: KeychainHelper.authService, account: KeychainHelper.tokenAccount) { // Use static property
            print("🔑 Token saved to Keychain.")
        }
    }

    func getAuthToken() -> String? {
        guard let data = readData(service: KeychainHelper.authService, account: KeychainHelper.tokenAccount) else { return nil } // Use static property
        return String(data: data, encoding: .utf8)
    }

     func saveUserId(_ id: Int) { // Save as Int directly if possible
        let idString = String(id)
        guard let data = idString.data(using: .utf8) else { return }
        if save(data, service: KeychainHelper.authService, account: KeychainHelper.userIdAccount) { // Use static property
            print("🔑 User ID saved to Keychain.")
        }
    }

    // No need for separate getUserId() string function if always converting to Int
    func getUserIdAsInt() -> Int? {
        guard let data = readData(service: KeychainHelper.authService, account: KeychainHelper.userIdAccount), // Use static property
              let userIdString = String(data: data, encoding: .utf8) else { return nil }
        return Int(userIdString)
    }

    func saveUserRole(_ role: UserRole) {
        guard let data = role.rawValue.data(using: .utf8) else { return }
         if save(data, service: KeychainHelper.authService, account: KeychainHelper.userRoleAccount) { // Use static property
            print("🔑 User Role saved to Keychain.")
         }
    }

     func getUserRole() -> UserRole? {
         guard let data = readData(service: KeychainHelper.authService, account: KeychainHelper.userRoleAccount), // Use static property
               let roleString = String(data: data, encoding: .utf8) else { return nil }
         return UserRole(rawValue: roleString)
     }

     // --- ADDED: Save Username ---
     func saveUsername(_ username: String) {
         guard let data = username.data(using: .utf8) else { return }
         if save(data, service: KeychainHelper.authService, account: KeychainHelper.usernameAccount) { // Use static property
             print("🔑 Username saved to Keychain.")
         }
     }

    func clearAuthCredentials() {
        // Use static properties
        _ = delete(service: KeychainHelper.authService, account: KeychainHelper.tokenAccount)
        _ = delete(service: KeychainHelper.authService, account: KeychainHelper.userIdAccount)
        _ = delete(service: KeychainHelper.authService, account: KeychainHelper.userRoleAccount)
        _ = delete(service: KeychainHelper.authService, account: KeychainHelper.usernameAccount) // Clear username too
        print("🔑 Auth credentials cleared from Keychain.")
    }
}
