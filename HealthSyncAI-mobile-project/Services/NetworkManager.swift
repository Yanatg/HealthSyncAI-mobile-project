// HealthSyncAI-mobile-project/Services/NetworkManager.swift
// UPDATED FILE
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
enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case requestFailed(Error) // Note: Comparing Errors directly is tricky
    case invalidResponse
    case decodingError(Error, data: Data?) // Note: Comparing Errors and Data directly is tricky
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
        case .decodingError(let error, let data): // Include data in log
            print("--- Underlying Decoding Error: \(error) ---")
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("--- Raw Data: \(dataString.prefix(1000))... ---") // Log raw data on decoding fail
            } else {
                print("--- Raw Data: (Not available or not UTF8) ---")
            }
            return "Could not understand the response from the server."
        case .unauthorized:
            return "Authentication failed. Please log out and log back in."
        case .custom(let message):
            // Attempt to parse the custom message for a user-friendly part
            return parseUserFriendlyMessage(from: message)
        }
    }

    // --- Implement Equatable ---
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL): return true
        case (.requestFailed, .requestFailed): return true // Simplified comparison
        case (.invalidResponse, .invalidResponse): return true
        case (.decodingError, .decodingError): return true // Simplified comparison
        case (.unauthorized, .unauthorized): return true
        case (.custom(let msg1), .custom(let msg2)): return msg1 == msg2
        default: return false
        }
    }

    // --- Helper Function (No Change Needed Here) ---
    private func parseUserFriendlyMessage(from message: String) -> String {
        if message.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{\"detail\":[") {
            return "Please check the information you entered and try again."
        }
        let prefixesToRemove = [
            "Error: ", "Server Error \\(\\d+\\): ", "Server returned status code \\d+: ",
            "Login Error: ", "Validation Error: ", "Failed to save note: "
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
                return userMessage
            }
        }
        let trimmedMessage = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedMessage.isEmpty ? "An unknown error occurred." : trimmedMessage
    }
}


// --- NetworkManager Class ---
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
    // Stays WITHOUT keyDecodingStrategy globally
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let validBaseURL = self.baseURL else { throw NetworkError.invalidURL }
        let fullEndpointPath = endpoint.starts(with: "/") ? String(endpoint.dropFirst()) : endpoint
        let urlWithPath = validBaseURL.appendingPathComponent(fullEndpointPath)
        guard let urlComponents = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: true) else { throw NetworkError.invalidURL }
        guard let url = urlComponents.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth { /* ... auth logic ... */
            if let token = keychainHelper.getAuthToken(), !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                 print("❌ Network Error: Auth required but token is missing or empty.")
                throw NetworkError.unauthorized
            }
        }
        request.httpBody = body

        var responseData: Data?
        do {
            print("🚀 Request (\(method)): \(url.absoluteString)")
            if let body = body, let bodyString = String(data: body, encoding: .utf8), !bodyString.isEmpty { print("   Body: \(bodyString.prefix(500))...") }

            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

            print("✅ Response Status: \(httpResponse.statusCode) for \(url.lastPathComponent)")
            if let responseBodyString = String(data: data, encoding: .utf8), !responseBodyString.isEmpty { print("   Response Body: \(responseBodyString.prefix(500))...") }
            else { print("   Response Body: (Empty)") }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder() // Create decoder instance here
                    // NO global strategy here - rely on CodingKeys in models like HealthRecord, Doctor, Chat etc.
                    if data.isEmpty { /* ... empty data handling ... */
                         if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T {
                            return empty
                        } else {
                             print("❌ Network Error: Received empty response body for status \(httpResponse.statusCode) but expected \(T.self).")
                            throw NetworkError.custom(message: "Received empty response body but expected content.")
                        }
                    }
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch { throw NetworkError.decodingError(error, data: responseData) }
            case 401: /* ... */ keychainHelper.clearAuthCredentials(); throw NetworkError.unauthorized
            // ... other cases ...
            case 400: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Bad Request")
            case 403: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Forbidden")
            case 404: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Resource Not Found at \(url.path)")
            case 422: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Validation Error")
            case 500...599: throw NetworkError.custom(message: "Server Error (\(httpResponse.statusCode)): \(decodeErrorDetail(from: data) ?? "Internal Server Error")")
            default: throw NetworkError.custom(message: "Server returned status code \(httpResponse.statusCode): \(decodeErrorDetail(from: data) ?? "Unknown server error")")

            }
        } catch let error as NetworkError { throw error }
          catch { throw NetworkError.requestFailed(error) }
    }


    // --- Multipart/Form-Data request function ---
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
        for (key, value) in fields { /* ... create body ... */
             body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        var responseData: Data?
        do {
            print("🚀 Request (\(method), Multipart): \(url.absoluteString)")
            print("   Fields: \(fields)")

            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }

            print("✅ Response Status: \(httpResponse.statusCode) for \(url.lastPathComponent)")
            if let responseBodyString = String(data: data, encoding: .utf8), !responseBodyString.isEmpty { print("   Response Body: \(responseBodyString.prefix(500))...") }
            else { print("   Response Body: (Empty)") }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder() // Create decoder instance here
                    // --- FIX: ADD Strategy back for models WITHOUT explicit CodingKeys (like AuthResponse) ---
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    // --- END FIX ---
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch { throw NetworkError.decodingError(error, data: responseData) }
            case 401: /* ... */ keychainHelper.clearAuthCredentials(); throw NetworkError.unauthorized
            // ... other cases ...
             case 400: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Bad Request")
            case 403: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Forbidden")
            case 404: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Resource Not Found at \(url.path)")
            case 422: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Validation Error")
            case 500...599: throw NetworkError.custom(message: "Server Error (\(httpResponse.statusCode)): \(decodeErrorDetail(from: data) ?? "Internal Server Error")")
            default: throw NetworkError.custom(message: "Server returned status code \(httpResponse.statusCode): \(decodeErrorDetail(from: data) ?? "Unknown server error")")

            }
        } catch let error as NetworkError { throw error }
          catch { throw NetworkError.requestFailed(error) }
    }


    // Helper function to decode errors
    private func decodeErrorDetail(from data: Data?) -> String? {
        guard let data = data, !data.isEmpty else { return nil }
        struct ErrorResponse: Decodable { let detail: String?; let message: String?; let error: String? }
        struct DetailItem: Decodable { let loc: [String]?; let msg: String?; let type: String? }
        struct StructuredErrorResponse: Decodable { let detail: [DetailItem]? }
        let decoder = JSONDecoder()
        if let structuredError = try? decoder.decode(StructuredErrorResponse.self, from: data), let firstDetailItem = structuredError.detail?.first, let firstErrorMsg = firstDetailItem.msg {
             let combinedMsg = structuredError.detail?.compactMap { $0.msg }.joined(separator: "; ")
             return combinedMsg ?? "Validation Error (Check fields)"
        }
        if let simpleError = try? decoder.decode(ErrorResponse.self, from: data) {
             if let detail = simpleError.detail { return detail }
             if let message = simpleError.message { return message }
             if let error = simpleError.error { return error }
        }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    // --- Specific API call functions (No changes needed below this line) ---

    // AUTH
    func login(credentials: LoginRequestBody) async throws -> AuthResponse {
        let endpoint = "/api/auth/login"
        let fields = ["username": credentials.username, "password": credentials.password]
        // This function uses sendMultipartFormDataRequest which NOW has the snake_case strategy for decoding AuthResponse
        return try await sendMultipartFormDataRequest(endpoint: endpoint, fields: fields, method: "POST")
    }
    func registerUser(data: RegistrationData) async throws -> AuthResponse {
        let endpoint = "/api/auth/register"
        let body = try data.encodeToJson() // RegistrationData handles its own encoding keys
        // This function uses request which does NOT have the global snake_case strategy for decoding AuthResponse
        // BUT AuthResponse itself relies on the strategy. This suggests registerUser should ideally return a different
        // response struct OR AuthResponse should have CodingKeys OR registration response should be decoded in sendMultipartFormDataRequest
        // For now, assuming login is the primary way to get AuthResponse needing the strategy. If registration *also*
        // returns AuthResponse, we'd need to adjust the request function or AuthResponse model.
        // LET'S ASSUME for now registration success doesn't *need* to decode AuthResponse here, or it's handled differently.
        // IF IT DOES RETURN AuthResponse, we'd need to set the strategy locally in the `request` function for this specific call,
        // or add CodingKeys to AuthResponse.
        // Given the previous fix was only in sendMultipartFormDataRequest, we'll stick to that.
        return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: false)
    }
    // APPOINTMENTS
    func fetchDoctorAppointments() async throws -> [Appointment] {
        let endpoint = "/api/appointment/my-appointments"
        return try await request(endpoint: endpoint, method: "GET", requiresAuth: true) // Uses request (no strategy), Appointment has CodingKeys
    }
    func fetchDoctors() async throws -> [Doctor] {
        let endpoint = "/api/appointment/doctors"
        return try await request(endpoint: endpoint, method: "GET", requiresAuth: true) // Uses request (no strategy), Doctor has CodingKeys
    }
    func createAppointment(requestData: CreateAppointmentRequest) async throws -> Appointment {
             // --- FIX: Add trailing slash to match the URL the server expects ---
             // The server was redirecting from /api/appointment to /api/appointment/,
             // and the redirected request was losing the Auth header.
             // Sending directly to the correct URL avoids the redirect.
             let endpoint = "/api/appointment/"
             // -------------------------------------------------------------------

             let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
             let body = try encoder.encode(requestData)
             // Uses the generic 'request' function which handles adding the auth header
             return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: true)
         }

    // HEALTH RECORDS
    func fetchPatientHealthRecords(patientId: Int) async throws -> [HealthRecord] {
        let endpoint = "/api/health-record/patient/\(patientId)"
        return try await request(endpoint: endpoint, method: "GET", requiresAuth: true) // Uses request (no strategy), HealthRecord has CodingKeys
    }
    func createDoctorNote(noteData: CreateDoctorNoteRequestBody) async throws -> HealthRecord {
        let endpoint = "/api/health-record/doctor-note"
        let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(noteData)
        return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: true) // Uses request (no strategy), HealthRecord has CodingKeys
    }
    // CHATBOT
    func fetchChatHistory() async throws -> [ChatRoomHistory] {
        let endpoint = "/api/chatbot/chats"
        return try await request(endpoint: endpoint, method: "GET", requiresAuth: true) // Uses request (no strategy), ChatRoomHistory/ChatMessage have CodingKeys
    }
     func sendChatMessage(message: ChatSymptomRequest) async throws -> ChatSymptomResponse {
         let endpoint = "/api/chatbot/symptom"
         let encoder = JSONEncoder(); encoder.keyEncodingStrategy = .convertToSnakeCase
         let body = try encoder.encode(message)
         return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: true) // Uses request (no strategy), ChatSymptomResponse has CodingKeys
     }
    // --- NEW FUNCTION ---
        func fetchPatientAppointments() async throws -> [Appointment] {
            // Endpoint specifically for the logged-in user's appointments
            // Ensure this matches the endpoint your backend uses for fetching
            // appointments based on the provided JWT token (usually the same
            // endpoint as fetching doctor appointments if the backend logic differentiates based on token/role)
            let endpoint = "/api/appointment/my-appointments"

            // Uses the generic 'request' function which adds the auth header
            // Assuming the response is an array of Appointment objects
            print("ℹ️ NetworkManager: Fetching appointments for logged-in user (Patient perspective) from \(endpoint)")
            return try await request(
                endpoint: endpoint,
                method: "GET",
                requiresAuth: true // This endpoint requires authentication
            )
        }
        // --- END NEW FUNCTION ---
}

// Define an empty response type for API calls that return 2xx but no body
struct EmptyResponse: Decodable {}
