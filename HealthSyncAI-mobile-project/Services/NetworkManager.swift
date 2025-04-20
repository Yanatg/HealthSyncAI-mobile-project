// Services/NetworkManager.swift
import Foundation

// --- Data extension for multipart helper ---
extension Data {
    /// Appends a string to the data using UTF8 encoding.
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
// --- End Data extension ---

// Define potential network errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingError(Error, data: Data?)
    case unauthorized
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not connect to the service. Please check the configuration."
        case .requestFailed:
             print("--- Underlying Request Failed Error: \(self) ---") // Log detail
            return "Could not connect to the network. Please check your internet connection and try again."
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .decodingError(let error, _):
            print("--- Underlying Decoding Error: \(error) ---") // Log detail
            return "Could not understand the response from the server."
        case .unauthorized:
            return "Authentication failed. Please log out and log back in."
        case .custom(let message):
            // Attempt to parse the custom message for a user-friendly part
            return parseUserFriendlyMessage(from: message)
        }
    }

    // *** MODIFY THIS HELPER FUNCTION ***
    private func parseUserFriendlyMessage(from message: String) -> String {
        // --- Step 1: Check for the detailed JSON validation error structure ---
        // A simple check: does it start with '{"detail":[' ?
        if message.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{\"detail\":[") {
            // It's likely the detailed 422 validation error. Provide a generic message.
            // We *could* try to parse the JSON and extract specific 'msg' fields,
            // but that adds complexity. A generic message is often sufficient here.
            return "Please check the information you entered and try again." // More user-friendly
            // Or slightly more specific: "There was an issue with the data provided. Please check the fields."
        }

        // --- Step 2: If not the detailed JSON, try removing known technical prefixes ---
        let prefixesToRemove = [
            "Error: ",
            "Server Error \\(\\d+\\): ", // Regex: Matches "Server Error (500): " etc.
            "Server returned status code \\d+: ", // Regex: Matches "Server returned status code 400: " etc.
            "Login Error: ",
            "Validation Error: ", // Generic validation prefix if not the detailed JSON
            "Failed to save note: "
            // Add other common prefixes if needed
        ]

        var userMessage = message

        for prefixPattern in prefixesToRemove {
            if let regex = try? NSRegularExpression(pattern: "^\(prefixPattern)", options: .caseInsensitive),
               let match = regex.firstMatch(in: userMessage, options: [], range: NSRange(location: 0, length: userMessage.utf16.count)) {
                userMessage.removeSubrange(Range(match.range, in: userMessage)!)
                userMessage = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                if let firstChar = userMessage.first {
                    userMessage = firstChar.uppercased() + String(userMessage.dropFirst())
                }
                // Return the message once a prefix is removed
                return userMessage
            }
        }

        // --- Step 3: If no specific pattern matched, return the trimmed original message ---
        // Consider if you want a generic fallback for completely unknown errors too.
        let trimmedMessage = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedMessage.isEmpty ? "An unknown error occurred." : trimmedMessage
        // return "An unexpected error occurred." // Alternative generic fallback for ALL unparsed errors
    }
}


// --- NetworkManager Class (No changes needed in the functions themselves) ---
class NetworkManager {
    static let shared = NetworkManager()

    private let baseURL: URL?
    private let keychainHelper = KeychainHelper.standard

    private init() {
        let urlString = "http://localhost:8000"
        if let url = URL(string: urlString) {
            self.baseURL = url
            print("✅ BaseURL initialized successfully: \(url.absoluteString)")
        } else {
            self.baseURL = nil
            assertionFailure("❌ CRITICAL: Failed to initialize BaseURL from string: \(urlString)")
            print("❌ CRITICAL: Failed to initialize BaseURL from string: \(urlString)")
        }
    }

    // --- Generic JSON request function ---
    // (Keep the implementation from the previous step - it already throws NetworkError)
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let validBaseURL = self.baseURL else { throw NetworkError.invalidURL }
        let fullEndpointPath = endpoint.starts(with: "/") ? String(endpoint.dropFirst()) : endpoint
        let urlWithPath = validBaseURL.appendingPathComponent(fullEndpointPath)
        guard var urlComponents = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: true) else { throw NetworkError.invalidURL }
        guard let url = urlComponents.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            if let token = keychainHelper.getAuthToken() { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
            else { throw NetworkError.unauthorized }
        }
        request.httpBody = body

        var responseData: Data?
        do {
            print("🚀 Request (JSON): \(method) \(url.absoluteString)")
            if let body = body, let bodyString = String(data: body, encoding: .utf8) { print("   Body: \(bodyString)") }

            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data

            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

            print("✅ Response Status: \(httpResponse.statusCode)")
            if let responseBodyString = String(data: data, encoding: .utf8), !responseBodyString.isEmpty { print("   Response Body: \(responseBodyString)") }
            else { print("   Response Body: (Empty)") }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if data.isEmpty {
                        if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T { return empty }
                        else { throw NetworkError.custom(message: "Received empty response body for status \(httpResponse.statusCode) but expected content.") }
                    }
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch {
                    print("❌ Decoding Error (JSON): \(error)")
                    throw NetworkError.decodingError(error, data: responseData)
                }
            case 401: keychainHelper.clearAuthCredentials(); throw NetworkError.unauthorized
            case 400: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Bad Request")
            case 403: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Forbidden")
            case 404: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Resource Not Found at \(url.path)")
            case 422: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Validation Error")
            case 500...599: throw NetworkError.custom(message: "Server Error (\(httpResponse.statusCode)): \(decodeErrorDetail(from: data) ?? "Internal Server Error")")
            default: throw NetworkError.custom(message: "Server returned status code \(httpResponse.statusCode): \(decodeErrorDetail(from: data) ?? "Unknown server error")")
            }
        } catch let error as NetworkError {
            print("❌ Caught NetworkError (JSON) in request func: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ URLSession Error (JSON) in request func: \(error)")
            throw NetworkError.requestFailed(error)
        }
    }

    // --- Multipart/Form-Data request function ---
    // (Keep the implementation from the previous step - it already throws NetworkError)
    func sendMultipartFormDataRequest<T: Decodable>(
        endpoint: String,
        fields: [String: String],
        method: String = "POST"
    ) async throws -> T {
        guard let validBaseURL = self.baseURL else { throw NetworkError.invalidURL }
        let fullEndpointPath = endpoint.starts(with: "/") ? String(endpoint.dropFirst()) : endpoint
        guard let url = URL(string: fullEndpointPath, relativeTo: validBaseURL) else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        var responseData: Data?
        do {
            print("🚀 Request (Multipart): \(method) \(url.absoluteString)")
            print("   Fields: \(fields)")

            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data

            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

            print("✅ Response Status: \(httpResponse.statusCode)")
            if let responseBodyString = String(data: data, encoding: .utf8), !responseBodyString.isEmpty { print("   Response Body: \(responseBodyString)") }
            else { print("   Response Body: (Empty)") }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch {
                    print("❌ Decoding Error (Multipart): \(error)")
                    throw NetworkError.decodingError(error, data: responseData)
                }
            case 401: throw NetworkError.unauthorized
            case 422: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Validation Error")
            default: throw NetworkError.custom(message: "Server returned status code \(httpResponse.statusCode): \(decodeErrorDetail(from: data) ?? "Unknown server error")")
            }
        } catch let error as NetworkError {
            print("❌ Caught NetworkError (Multipart): \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ URLSession Error (Multipart): \(error)")
            throw NetworkError.requestFailed(error)
        }
    }

    // Helper function to decode errors (Handles basic { "detail": "..." } structure)
    private func decodeErrorDetail(from data: Data?) -> String? {
        guard let data = data, !data.isEmpty else { return nil }

        // First, try decoding the standard {"detail": "..."} structure
        struct ErrorResponse: Decodable {
            let detail: String?
            // Add other potential error fields if your API uses them
            let message: String?
            let error: String?
            // If errors can be arrays or objects:
            // let errors: [String]? or let errors: [String: [String]]?
        }

        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return errorResponse.detail ?? errorResponse.message ?? errorResponse.error // Return first non-nil message
        }

        // If that fails, return the raw string representation as a fallback
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // --- Specific API call functions ---

    func login(credentials: LoginRequestBody) async throws -> AuthResponse {
        let endpoint = "/api/auth/login" // Ensure leading slash if base URL doesn't have trailing slash
        let fields = [
            "username": credentials.username,
            "password": credentials.password,
        ]
        return try await sendMultipartFormDataRequest(endpoint: endpoint, fields: fields, method: "POST")
    }
    func registerUser(data: RegistrationData) async throws -> AuthResponse {
            let endpoint = "/api/auth/register" // Correct endpoint path

            // Use the helper method which now sets the snake_case strategy
            // specific for ENCODING the registration request body.
            let body = try data.encodeToJson()

            print("--- Registration Request Body ---")
            print(String(data: body, encoding: .utf8) ?? "Could not print body")
            print("-------------------------------")


            // Use the generic JSON request function for the POST request.
            // The DECODER strategy inside `request` will handle the AuthResponse.
            return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: false)
        }
    func fetchDoctorAppointments() async throws -> [Appointment] {
        let endpoint = "/api/appointment/my-appointments"
        // Use the generic JSON request function
        return try await request(endpoint: endpoint, method: "GET", requiresAuth: true)
    }

    func fetchPatientHealthRecords(patientId: Int) async throws -> [HealthRecord] {
        let endpoint = "/api/health-record/patient/\(patientId)"
        return try await request(endpoint: endpoint, method: "GET", requiresAuth: true)
    }

    func createDoctorNote(noteData: CreateDoctorNoteRequestBody) async throws -> HealthRecord {
        let endpoint = "/api/health-record/doctor-note"
        let encoder = JSONEncoder()
        // Ensure snake_case encoding if the API expects it for request bodies
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(noteData)
        return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: true)
    }
}

// Define an empty response type for API calls that return 2xx but no body
struct EmptyResponse: Decodable {}
