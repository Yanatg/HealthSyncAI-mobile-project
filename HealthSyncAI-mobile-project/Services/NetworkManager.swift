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
    case decodingError(Error, data: Data?) // Add associated data
    case unauthorized
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API endpoint URL is invalid or could not be constructed."
        case .requestFailed(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the server (not HTTP)."
        case .decodingError(let error, let data):
            // Provide more context about the decoding error
            var details = "Failed to decode the response: \(error.localizedDescription)"
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                details += "\n--- Raw Response Data ---\n\(dataString)\n-------------------------"
            } else {
                 details += "\n(Could not retrieve raw response data)"
            }
             if let decodingError = error as? DecodingError {
                 details += "\n--- Decoding Error Context ---\n\(decodingError)\n----------------------------"
             }
            return details
        case .unauthorized:
            return "Authentication failed or token expired. Please login again."
        case .custom(let message): return message
        }
    }
}

// A basic singleton Network Manager
class NetworkManager {
    static let shared = NetworkManager()

    private let baseURL: URL?
    private let keychainHelper = KeychainHelper.standard

    private init() {
        // <<< --- ENSURE THIS IS YOUR CORRECT BACKEND URL --- >>>
        let urlString = "http://localhost:8000" // Use your actual backend IP/domain
        // <<< --- END REPLACE --- >>>

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
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {

        guard let validBaseURL = self.baseURL else {
            print("❌ Cannot make JSON request: BaseURL is invalid.")
            throw NetworkError.invalidURL
        }

        let fullEndpointPath = endpoint.starts(with: "/") ? String(endpoint.dropFirst()) : endpoint
        let urlWithPath = validBaseURL.appendingPathComponent(fullEndpointPath)

        guard var urlComponents = URLComponents(url: urlWithPath, resolvingAgainstBaseURL: true) else {
            print("❌ FAILED to create URLComponents from \(urlWithPath.absoluteString)")
            throw NetworkError.invalidURL
        }
         // Example: Add query parameters if needed
         // urlComponents.queryItems = [URLQueryItem(name: "param", value: "value")]

        guard let url = urlComponents.url else {
            print("❌ FAILED to get URL from URLComponents")
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept") // Important for receiving JSON

        if requiresAuth {
            if let token = keychainHelper.getAuthToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                // print("🔑 Using Auth Token for JSON request: \(token)") // Optionally log token for debug
            } else {
                print("⚠️ Auth required for JSON request, but no token found.")
                throw NetworkError.unauthorized
            }
        }

        request.httpBody = body

        // Execute and handle response
        var responseData: Data? // Variable to store data for error logging
        do {
            print("🚀 Request (JSON): \(method) \(url.absoluteString)")
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                print("   Body: \(bodyString)")
            }

            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data // Store data for potential error logging

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Failed to cast JSON response to HTTPURLResponse. Actual type was: \(type(of: response))")
                throw NetworkError.invalidResponse
            }

            print("✅ Response Status: \(httpResponse.statusCode)")
            if let responseBodyString = String(data: data, encoding: .utf8), !responseBodyString.isEmpty {
                // Limit printing large responses in production
                // print("   Response Body: \(responseBodyString.prefix(1000))...")
                 print("   Response Body: \(responseBodyString)") // Print full for debug
            } else {
                print("   Response Body: (Empty)")
            }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    // Key strategy MUST match JSON keys (snake_case)
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if data.isEmpty && T.self == EmptyResponse.self {
                         if let empty = EmptyResponse() as? T { return empty }
                         else { throw NetworkError.custom(message: "Type mismatch for empty response.") }
                    } else if data.isEmpty {
                        // Allow empty body for certain successful status codes like 204 No Content
                        if httpResponse.statusCode == 204 && T.self == EmptyResponse.self {
                             if let empty = EmptyResponse() as? T { return empty }
                             else { throw NetworkError.custom(message: "Type mismatch for 204 empty response.") }
                        }
                        // Throw error if expecting content but body is empty
                        throw NetworkError.custom(message: "Received empty response body for status \(httpResponse.statusCode) but expected content.")
                    }
                    // ***** THE ACTUAL DECODING HAPPENS HERE *****
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch {
                    print("❌ Decoding Error (JSON): \(error)")
                    // Pass the actual data along with the error
                    throw NetworkError.decodingError(error, data: responseData) // Pass data here
                }
            case 401:
                keychainHelper.clearAuthCredentials() // Clear potentially invalid token
                throw NetworkError.unauthorized
            case 400: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Bad Request")
            case 403: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Forbidden")
            case 404: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Resource Not Found at \(url.path)")
            case 422: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Validation Error") // Common for invalid input
            case 500...599: throw NetworkError.custom(message: "Server Error (\(httpResponse.statusCode)): \(decodeErrorDetail(from: data) ?? "Internal Server Error")")
            default: throw NetworkError.custom(message: "Server returned status code \(httpResponse.statusCode): \(decodeErrorDetail(from: data) ?? "Unknown server error")")
            }
        } catch let error as NetworkError {
            print("❌ Caught NetworkError (JSON) in request func: \(error.localizedDescription)")
            throw error // Re-throw the specific NetworkError
        } catch {
             // Catch URLSession errors (e.g., network connection lost)
            print("❌ URLSession Error (JSON) in request func: \(error)")
            throw NetworkError.requestFailed(error)
        }
    }

    // --- Multipart/Form-Data request function ---
    // (Keep your existing multipart function as is, just ensure baseURL handling is safe like above)
    func sendMultipartFormDataRequest<T: Decodable>(
        endpoint: String,
        fields: [String: String],
        method: String = "POST"
    ) async throws -> T {

        guard let validBaseURL = self.baseURL else {
            print("❌ Cannot make Multipart request: BaseURL is invalid.")
            throw NetworkError.invalidURL
        }

        let fullEndpointPath = endpoint.starts(with: "/") ? String(endpoint.dropFirst()) : endpoint
        guard let url = URL(string: fullEndpointPath, relativeTo: validBaseURL) else {
             print("❌ FAILED to create URL from baseURL + endpoint (Multipart)")
             throw NetworkError.invalidURL
         }


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

         // Add Auth token if needed for multipart requests (login usually doesn't, but others might)
         // if requiresAuth { ... add token header ... }

        var responseData: Data? // For error logging
        do {
            print("🚀 Request (Multipart): \(method) \(url.absoluteString)")
            print("   Fields: \(fields)")

            let (data, response) = try await URLSession.shared.data(for: request)
             responseData = data

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Failed to cast Multipart response to HTTPURLResponse. Actual type was: \(type(of: response))")
                throw NetworkError.invalidResponse
            }

            print("✅ Response Status: \(httpResponse.statusCode)")
             if let responseBodyString = String(data: data, encoding: .utf8), !responseBodyString.isEmpty {
                 print("   Response Body: \(responseBodyString)")
             } else {
                 print("   Response Body: (Empty)")
             }

            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase // <<< ENSURE THIS IS STILL HERE
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch {
                    print("❌ Decoding Error (Multipart): \(error)")
                    throw NetworkError.decodingError(error, data: responseData) // Pass data
                }
            case 401: throw NetworkError.unauthorized // Or custom message if specific login error
            case 422: throw NetworkError.custom(message: decodeErrorDetail(from: data) ?? "Validation Error (e.g., invalid credentials)")
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
