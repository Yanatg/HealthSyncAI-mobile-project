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
    case invalidURL  // Error 0
    case requestFailed(Error)  // Error 1
    case invalidResponse  // Error 2
    case decodingError(Error)  // Error 3
    case unauthorized  // Error 4
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return
                "The API endpoint URL is invalid or could not be constructed."  // Updated description
        case .requestFailed(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the server (not HTTP)."  // Updated description
        case .decodingError(let error):
            return
                "Failed to decode the response: \(error.localizedDescription)"
        case .unauthorized:
            return "Authentication failed or token expired. Please login again."
        case .custom(let message): return message
        }
    }
}

// A basic singleton Network Manager
class NetworkManager {
    static let shared = NetworkManager()

    // --- Use optional URL and initialize safely ---
    private let baseURL: URL?

    private let keychainHelper = KeychainHelper.standard

    private init() {
        // --- Initialize baseURL safely ---
        // <<< --- REPLACE THE STRING HERE WITH YOUR IP ADDRESS URL --- >>>
        let urlString = "http://localhost:8000/"  // Example IP, use yours!
        // <<< --- END REPLACE --- >>>

        if let url = URL(string: urlString) {
            self.baseURL = url
            print("✅ BaseURL initialized successfully: \(url.absoluteString)")
        } else {
            self.baseURL = nil
            // This is critical - log prominently or assert in debug builds
            assertionFailure(
                "❌ CRITICAL: Failed to initialize BaseURL from string: \(urlString)"
            )
            print(
                "❌ CRITICAL: Failed to initialize BaseURL from string: \(urlString)"
            )
        }
    }

    
    // --- Generic JSON request function ---
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {

        // Safely unwrap baseURL
        guard let validBaseURL = self.baseURL else {
            print("❌ Cannot make JSON request: BaseURL is invalid.")
            throw NetworkError.invalidURL
        }

        // Construct URLComponents safely
        guard
            var urlComponents = URLComponents(
                url: validBaseURL.appendingPathComponent(endpoint),
                resolvingAgainstBaseURL: true
            )
        else {
            print(
                "❌ FAILED to create URLComponents from \(validBaseURL.absoluteString) and endpoint \(endpoint)"
            )
            throw NetworkError.invalidURL
        }
        // Add query parameters here if needed in the future
        // urlComponents.queryItems = [...]

        guard let url = urlComponents.url else {
            print("❌ FAILED to get URL from URLComponents")
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add Authorization header if required
        if requiresAuth {
            if let token = keychainHelper.getAuthToken() {
                request.setValue(
                    "Bearer \(token)",
                    forHTTPHeaderField: "Authorization"
                )
                print("🔑 Using Auth Token for JSON request.")
            } else {
                print("⚠️ Auth required for JSON request, but no token found.")
                throw NetworkError.unauthorized
            }
        }

        request.httpBody = body

        // Execute and handle response
        do {
            print("🚀 Request (JSON): \(method) \(url.absoluteString)")
            if let body = body,
                let bodyString = String(data: body, encoding: .utf8)
            {
                print("   Body: \(bodyString)")
            }

            let (data, response): (Data, URLResponse)  // <<< FIX: Add type annotation
            do {
                (data, response) = try await URLSession.shared.data(
                    for: request
                )
                print("✅ URLSession returned successfully.")
                print("   Response Type: \(type(of: response))")
                // print("   Response Description: \(response)") // Can be verbose
            } catch {
                print(
                    "❌ Error directly from URLSession.shared.data (JSON): \(error)"
                )
                throw NetworkError.requestFailed(error)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print(
                    "❌ Failed to cast JSON response to HTTPURLResponse. Actual type was: \(type(of: response))"
                )
                throw NetworkError.invalidResponse
            }

            print("✅ Response Status: \(httpResponse.statusCode)")
            if let responseBodyString = String(data: data, encoding: .utf8),
                !responseBodyString.isEmpty
            {
                print("   Response Body: \(responseBodyString)")
            } else {
                print("   Response Body: (Empty)")
            }

            // Handle status codes
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    if data.isEmpty && T.self == EmptyResponse.self {
                        if let empty = EmptyResponse() as? T {
                            return empty
                        } else {
                            throw NetworkError.custom(
                                message: "Type mismatch for empty response."
                            )
                        }
                    } else if data.isEmpty {
                        throw NetworkError.custom(
                            message:
                                "Received empty response body for status \(httpResponse.statusCode)"
                        )
                    }
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch {
                    print("❌ Decoding Error (JSON): \(error)")
                    throw NetworkError.decodingError(error)
                }
            case 401:
                keychainHelper.clearAuthCredentials()
                throw NetworkError.unauthorized
            case 400:
                let errorDetail = decodeErrorDetail(from: data) ?? "Bad Request"
                throw NetworkError.custom(message: "Error: \(errorDetail)")
            case 403:
                let errorDetail = decodeErrorDetail(from: data) ?? "Forbidden"
                throw NetworkError.custom(message: "Error: \(errorDetail)")
            case 404:
                let errorDetail =
                    decodeErrorDetail(from: data) ?? "Resource Not Found"
                throw NetworkError.custom(message: "Error: \(errorDetail)")
            case 500...599:
                let errorDetail =
                    decodeErrorDetail(from: data) ?? "Internal Server Error"
                throw NetworkError.custom(
                    message:
                        "Server Error (\(httpResponse.statusCode)): \(errorDetail)"
                )
            default:
                let errorDetail =
                    decodeErrorDetail(from: data) ?? "Unknown server error"
                throw NetworkError.custom(
                    message:
                        "Server returned status code \(httpResponse.statusCode): \(errorDetail)"
                )
            }
        } catch let error as NetworkError {
            print("❌ Caught NetworkError (JSON): \(error.localizedDescription)")
            throw error
        } catch {
            // Catch URLSession errors not already caught
            print("❌ URLSession Error (JSON): \(error)")
            throw NetworkError.requestFailed(error)
        }
    }
    // --- END Generic JSON request function ---

    // --- Multipart/Form-Data request function ---
    func sendMultipartFormDataRequest<T: Decodable>(
        endpoint: String,
        fields: [String: String],
        method: String = "POST"
    ) async throws -> T {

        // Safely unwrap baseURL
        guard let validBaseURL = self.baseURL else {
            print("❌ Cannot make Multipart request: BaseURL is invalid.")
            throw NetworkError.invalidURL
        }

        // --- Add Logging Here ---
        print("--- Creating URL (Multipart) ---")
        print("Base URL: \(validBaseURL.absoluteString)")
        print("Endpoint: \(endpoint)")
        // --- End Logging ---

        guard let url = URL(string: endpoint, relativeTo: validBaseURL) else {
            print("❌ FAILED to create URL from baseURL + endpoint (Multipart)")
            throw NetworkError.invalidURL  // Error 0 likely thrown here
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        // Create boundary and set Content-Type
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        // Create the request body
        var body = Data()
        for (key, value) in fields {
            body.append("--\(boundary)\r\n")
            body.append(
                "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
            )
            body.append("\(value)\r\n")
        }
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        // Execute and handle response
        do {
            print("🚀 Request (Multipart): \(method) \(url.absoluteString)")
            print("   Fields: \(fields)")

            let (data, response): (Data, URLResponse)  // <<< FIX: Add type annotation
            do {
                (data, response) = try await URLSession.shared.data(
                    for: request
                )
                print("✅ URLSession returned successfully.")
                print("   Response Type: \(type(of: response))")
                // print("   Response Description: \(response)") // Can be verbose
            } catch {
                print(
                    "❌ Error directly from URLSession.shared.data (Multipart): \(error)"
                )
                throw NetworkError.requestFailed(error)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print(
                    "❌ Failed to cast Multipart response to HTTPURLResponse. Actual type was: \(type(of: response))"
                )
                throw NetworkError.invalidResponse  // Error 2
            }

            print("✅ Response Status: \(httpResponse.statusCode)")
            if let responseBodyString = String(data: data, encoding: .utf8),
                !responseBodyString.isEmpty
            {
                print("   Response Body: \(responseBodyString)")
            } else {
                print("   Response Body: (Empty)")
            }

            // Handle status codes
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoder = JSONDecoder()
//                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedObject = try decoder.decode(T.self, from: data)
                    return decodedObject
                } catch {
                    // --- Enhanced Logging ---
                    print("❌ Decoding Error (Multipart): \(error)")
                    print(
                        "   Error Localized Description: \(error.localizedDescription)"
                    )
                    if let decodingError = error as? DecodingError {
                        print("   Decoding Error Context: \(decodingError)")  // Provides detailed context
                    }
                    // --- End Enhanced Logging ---
                    throw NetworkError.decodingError(error)
                }
            case 401:
                let errorDetail =
                    decodeErrorDetail(from: data) ?? "Invalid Credentials"
                throw NetworkError.custom(message: errorDetail)
            case 422:
                let errorDetail =
                    decodeErrorDetail(from: data) ?? "Validation Error"
                throw NetworkError.custom(
                    message: "Login Error: \(errorDetail)"
                )
            default:
                let errorDetail =
                    decodeErrorDetail(from: data)
                    ?? "Unknown server error during login"
                throw NetworkError.custom(
                    message:
                        "Server returned status code \(httpResponse.statusCode): \(errorDetail)"
                )
            }
        } catch let error as NetworkError {
            print(
                "❌ Caught NetworkError (Multipart): \(error.localizedDescription)"
            )
            throw error
        } catch {
            print("❌ URLSession Error (Multipart): \(error)")
            throw NetworkError.requestFailed(error)
        }
    }
    // --- END Multipart/Form-Data request function ---

    // Helper function to decode errors
    private func decodeErrorDetail(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            let detail: String?  // Adjust if your API error structure is different
        }
        if let errorResponse = try? JSONDecoder().decode(
            ErrorResponse.self,
            from: data
        ) {
            return errorResponse.detail
        }
        return String(data: data, encoding: .utf8)?.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    // --- Specific API call function for Login ---
    // Uses the multipart sender internally
    func login(credentials: LoginRequestBody) async throws -> AuthResponse {
        let endpoint = "api/auth/login"  // Relative endpoint path

        let fields = [
            "username": credentials.username,
            "password": credentials.password,
        ]
        // Call the multipart request sender
        return try await sendMultipartFormDataRequest(
            endpoint: endpoint,
            fields: fields,
            method: "POST"
        )
    }
    // --- End login function ---

    func fetchDoctorAppointments() async throws -> [Appointment] {
            let endpoint = "api/appointment/my-appointments" // Endpoint from React DoctorNoteForm
            return try await request(endpoint: endpoint, method: "GET", requiresAuth: true)
        }

        // --- Fetch Health Records for a Specific Patient ---
        func fetchPatientHealthRecords(patientId: Int) async throws -> [HealthRecord] {
            let endpoint = "api/health-record/patient/\(patientId)" // Endpoint from React PatientHealthRecordPage
            // Note: The response might be a single object or an array. Adjust T if needed.
            // Assuming the API returns an array of records for the patient.
            return try await request(endpoint: endpoint, method: "GET", requiresAuth: true)
        }

        // --- Create a New Doctor Note ---
        func createDoctorNote(noteData: CreateDoctorNoteRequestBody) async throws -> HealthRecord {
            // Endpoint from React NewDoctorNotePage
            // The request body structure is defined by CreateDoctorNoteRequestBody
            let endpoint = "api/health-record/doctor-note"
            let body = try JSONEncoder().encode(noteData)

            // Use the generic request function for POST with JSON body
            return try await request(endpoint: endpoint, method: "POST", body: body, requiresAuth: true)
        }
}

// Define an empty response type for API calls that return 2xx but no body
struct EmptyResponse: Decodable {}
