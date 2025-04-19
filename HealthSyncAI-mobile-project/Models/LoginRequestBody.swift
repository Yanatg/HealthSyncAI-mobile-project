// Models/LoginRequestBody.swift (Adjust field names if API expects something different)
import Foundation

struct LoginRequestBody: Codable {
    let username: String // Or 'email' if your API uses that
    let password: String
    // Note: The 'role' is handled separately in the logic, not usually part of the body
    // unless your specific API requires it in the login request itself.
}
