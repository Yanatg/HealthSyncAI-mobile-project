// Models/AuthResponse.swift
import Foundation

struct AuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let userId: Int // Correct type based on your API response

    // Using CodingKeys is good practice even if defaults work, for clarity
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case userId = "user_id"
    }
}
