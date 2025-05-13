import Foundation

// Represents a single chat message exchange within a room
struct ChatMessage: Codable, Identifiable {
    let id: Int
    let inputText: String
    let modelResponse: String
    let triageAdvice: String?
    let createdAt: String // Keep as ISO string
    let roomNumber: Int

    enum CodingKeys: String, CodingKey {
        case id
        case inputText = "input_text"
        case modelResponse = "model_response"
        case triageAdvice = "triage_advice"
        case createdAt = "created_at"
        case roomNumber = "room_number"
    }

    // Helper for display formatting
    var formattedCreatedAt: String { formatDate(createdAt) }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds, .withTimeZone]
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        // Fallback
         let altFormatter = ISO8601DateFormatter()
         altFormatter.formatOptions = .withInternetDateTime
         if let altDate = altFormatter.date(from: dateString) {
              let displayFormatter = DateFormatter()
              displayFormatter.dateStyle = .short
              displayFormatter.timeStyle = .short
              return displayFormatter.string(from: altDate)
          }
        print("⚠️ Could not parse chat message date: \(dateString)")
        return dateString
    }
}

// Represents the chat history for a specific room
struct ChatRoomHistory: Codable, Identifiable {
    var id: Int { roomNumber } // Use roomNumber as the unique ID for Identifiable
    let roomNumber: Int
    let chats: [ChatMessage] // Array of messages in this room

    enum CodingKeys: String, CodingKey {
        case roomNumber = "room_number"
        case chats
    }
}

// Simple struct to represent a message displayed in the UI
struct DisplayMessage: Identifiable {
    let id = UUID()
    let sender: SenderType
    let text: String
}

enum SenderType {
    case user, bot
}

// Request body for sending a message
struct ChatSymptomRequest: Codable {
    let symptomText: String
    let roomNumber: Int? // Optional for the very first message in a new chat

    enum CodingKeys: String, CodingKey {
        case symptomText = "symptom_text"
        case roomNumber = "room_number"
    }
}

// Expected response from sending a message
struct ChatSymptomResponse: Codable {
    let analysis: String? // Bot's main response
    let triageAdvice: String?

    enum CodingKeys: String, CodingKey {
        case analysis
        case triageAdvice = "triage_advice"
    }
}
