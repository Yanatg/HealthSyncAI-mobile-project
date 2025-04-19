// Utils/KeychainHelper.swift
import Foundation
import Security

class KeychainHelper {
    static let standard = KeychainHelper()
    private init() {}

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
    private let authService = "com.yourapp.auth" // Use your bundle ID or a unique name
    private let tokenAccount = "userToken"
    private let userIdAccount = "userId"
    private let userRoleAccount = "userRole"

    func saveAuthToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        if save(data, service: authService, account: tokenAccount) {
            print("🔑 Token saved to Keychain.")
        }
    }

    func getAuthToken() -> String? {
        guard let data = readData(service: authService, account: tokenAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveUserId(_ id: String) {
        guard let data = id.data(using: .utf8) else { return }
        if save(data, service: authService, account: userIdAccount) {
            print("🔑 User ID saved to Keychain.")
        }
    }

    // << --- ADDED THIS FUNCTION --- >>
    func getUserId() -> String? {
        guard let data = readData(service: authService, account: userIdAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    // << --- END ADDED FUNCTION --- >>


    // Now getUserIdAsInt() can call the function above
    func getUserIdAsInt() -> Int? {
        guard let userIdString = getUserId() else { return nil } // Line 110 should now compile
        return Int(userIdString)
    }


    func saveUserRole(_ role: UserRole) {
        guard let data = role.rawValue.data(using: .utf8) else { return }
         if save(data, service: authService, account: userRoleAccount) {
            print("🔑 User Role saved to Keychain.")
         }
    }

     func getUserRole() -> UserRole? {
         guard let data = readData(service: authService, account: userRoleAccount),
               let roleString = String(data: data, encoding: .utf8) else { return nil }
         return UserRole(rawValue: roleString)
     }


    func clearAuthCredentials() {
        _ = delete(service: authService, account: tokenAccount)
        _ = delete(service: authService, account: userIdAccount)
        _ = delete(service: authService, account: userRoleAccount)
         print("🔑 Auth credentials cleared from Keychain.")
    }
}
