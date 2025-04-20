// Models/AuthResponse.swift
import Foundation

struct AuthResponse: Codable {
    let accessToken: String // Swift camelCase
    let tokenType: String   // Swift camelCase
    let userId: Int         // Swift camelCase
}
