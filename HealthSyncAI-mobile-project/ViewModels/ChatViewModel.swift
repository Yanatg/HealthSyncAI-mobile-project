// HealthSyncAI-mobile-project/ViewModels/ChatViewModel.swift
// UPDATED FILE
import Foundation
import Combine
import SwiftUI // For Color

@MainActor
class ChatViewModel: ObservableObject {

    // --- UI State ---
    @Published var currentMessages: [DisplayMessage] = [
        DisplayMessage(sender: .bot, text: "Hello, how can I help you?")
    ]
    @Published var currentInput: String = ""
    @Published var isLoadingResponse: Bool = false // For chatbot message response
    @Published var isConfirmingAppointment: Bool = false // For appointment creation

    @Published var selectedSection: ChatSection = .chatbot
    @Published var chatHistory: [ChatRoomHistory] = []
    @Published var selectedHistoryRoomId: Int? = nil
    @Published var isLoadingHistory: Bool = false
    @Published var historyError: String? = nil
    @Published var currentRoomNumber: Int? = nil // For the *next* new chat

    @Published var lastTriageAdvice: String? = nil // Stores advice like "schedule_appointment"
    @Published var showSchedulingUI: Bool = false // Controls showing the BookingBoxView

    @Published var errorMessage: String? = nil // General errors

    // --- Child ViewModel ---
    // We create BookingViewModel when scheduling starts
    @Published var bookingViewModel: BookingViewModel? = nil

    // --- Dependencies ---
    @Published var userFirstName: String = "" // Display name
    private let networkManager = NetworkManager.shared
    private let appState: AppState // Needs AppState for auth status/logout
    private let keychainHelper = KeychainHelper.standard // Add KeychainHelper instance

    // Keep track of the room number for the *current* active chat session
    private var activeChatRoomNumber: Int? = nil

    // --- Initialization ---
    init(appState: AppState) {
        self.appState = appState
        self.userFirstName = keychainHelper.getFirstName() ?? "there" // Use KeychainHelper instance
        fetchHistory() // Fetch history on init
    }

    // --- Computed Properties ---
    var selectedHistoryMessages: [DisplayMessage] {
        guard selectedSection == .history,
              let roomId = selectedHistoryRoomId,
              let room = chatHistory.first(where: { $0.roomNumber == roomId })
        else {
            return []
        }
        // Convert stored ChatMessage to DisplayMessage, sorted chronologically
        return room.chats
            .sorted { $0.id < $1.id } // Ensure correct order by API ID
            .flatMap { chatMsg in
                [
                    DisplayMessage(sender: .user, text: chatMsg.inputText),
                    DisplayMessage(sender: .bot, text: chatMsg.modelResponse)
                    // Optionally display historical triage advice here if needed
                ]
            }
    }

    var canSendMessage: Bool {
        !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoadingResponse && !isConfirmingAppointment
    }

    var canStartNewChat: Bool {
        !isLoadingResponse && !isConfirmingAppointment
    }

    var canScheduleAppointment: Bool {
        !isLoadingResponse && !isConfirmingAppointment
    }

    var showSchedulePrompt: Bool {
        lastTriageAdvice == "schedule_appointment" && !showSchedulingUI && selectedSection == .chatbot
    }

    var canConfirmBooking: Bool {
        bookingViewModel?.selectedDoctor != nil &&
        bookingViewModel?.selectedTimeSlot != nil &&
        !isConfirmingAppointment
    }

    // --- Actions ---

    func selectSection(_ section: ChatSection) {
        selectedSection = section
        if section == .history && selectedHistoryRoomId == nil {
            // Auto-select the most recent history room if none is selected
            selectedHistoryRoomId = chatHistory.first?.roomNumber // History is reversed (newest first)
        }
        // Clear transient states when switching sections
        lastTriageAdvice = nil
        errorMessage = nil
    }

    func fetchHistory() {
        guard !isLoadingHistory else { return }
        print("Fetching chat history...")
        isLoadingHistory = true
        historyError = nil

        Task {
            do {
                let history = try await networkManager.fetchChatHistory()
                // Sort rooms by highest room number first (most recent)
                self.chatHistory = history.sorted { $0.roomNumber > $1.roomNumber }

                // Determine the next available room number
                if let highestRoomNum = self.chatHistory.first?.roomNumber {
                    self.currentRoomNumber = highestRoomNum + 1
                } else {
                    self.currentRoomNumber = 1 // Start at 1 if no history
                }
                print("✅ Fetched \(self.chatHistory.count) chat rooms. Next room number: \(self.currentRoomNumber ?? 0)")

                // If history section is active and no room selected, select the newest one
                if self.selectedSection == .history && self.selectedHistoryRoomId == nil {
                    self.selectedHistoryRoomId = self.chatHistory.first?.roomNumber
                }

            } catch let error as NetworkError {
                // --- UPDATED: Check error case, not direct equality ---
                if case .unauthorized = error {
                    handleUnauthorized()
                } else {
                    historyError = "Failed to load chat history: \(error.localizedDescription)"
                    print("❌ NetworkError fetching history: \(error)")
                }
            } catch {
                historyError = "An unexpected error occurred: \(error.localizedDescription)"
                print("❌ Unexpected error fetching history: \(error)")
            }
            isLoadingHistory = false
        }
    }

    func sendMessage() {
        guard canSendMessage else { return }

        let messageText = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        currentInput = "" // Clear input immediately

        // Add user message to UI
        currentMessages.append(DisplayMessage(sender: .user, text: messageText))
        isLoadingResponse = true
        errorMessage = nil
        lastTriageAdvice = nil // Clear previous advice

        // If this is the first message of a new chat, use currentRoomNumber
        if activeChatRoomNumber == nil {
            activeChatRoomNumber = currentRoomNumber
        }

        print("Sending message: '\(messageText)' to room: \(activeChatRoomNumber ?? -1)")

        let requestBody = ChatSymptomRequest(symptomText: messageText, roomNumber: activeChatRoomNumber)

        Task {
            do {
                let response = try await networkManager.sendChatMessage(message: requestBody)

                // Add bot response to UI
                currentMessages.append(DisplayMessage(sender: .bot, text: response.analysis ?? "Sorry, I couldn't process that."))

                // Store triage advice
                if let advice = response.triageAdvice, !advice.isEmpty {
                    self.lastTriageAdvice = advice
                    print("ℹ️ Received triage advice: \(advice)")
                }

                // If this was the first message and successful, increment for the *next* potential chat
                if requestBody.roomNumber == currentRoomNumber {
                     // Refetch history to include the new room if it wasn't there before
                     // This ensures the history dropdown/list updates correctly.
                     let roomExisted = chatHistory.contains { $0.roomNumber == currentRoomNumber }
                     if !roomExisted {
                         fetchHistory() // Fetch again to get the new room listed
                     } else {
                         // If the room already existed (e.g., user revisited an old chat),
                         // we might still want to update the specific room's messages in chatHistory.
                         // This requires finding the room and updating its 'chats' array.
                         // For simplicity now, we only refetch if it's a *brand new* room number.
                     }
                     // Increment for the *next* chat only after the first message of the current one succeeds
                     currentRoomNumber = (currentRoomNumber ?? 0) + 1

                 }


            } catch let error as NetworkError {
                 // --- UPDATED: Check error case, not direct equality ---
                 if case .unauthorized = error {
                    handleUnauthorized()
                } else {
                    errorMessage = "Failed to send message: \(error.localizedDescription)"
                    currentMessages.append(DisplayMessage(sender: .bot, text: "Sorry, something went wrong. \(error.localizedDescription)"))
                    print("❌ NetworkError sending message: \(error)")
                }
            } catch {
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                currentMessages.append(DisplayMessage(sender: .bot, text: "Sorry, an unexpected error occurred."))
                print("❌ Unexpected error sending message: \(error)")
            }
            isLoadingResponse = false
        }
    }

    func startNewChat() {
        guard canStartNewChat else { return }
        print("Starting new chat...")

        // Reset chat-specific state
        currentMessages = [DisplayMessage(sender: .bot, text: "Hello, how can I help you?")]
        currentInput = ""
        isLoadingResponse = false
        lastTriageAdvice = nil
        errorMessage = nil
        activeChatRoomNumber = nil // Ensures the next message uses currentRoomNumber

        // Reset scheduling state
        showSchedulingUI = false
        bookingViewModel = nil
        isConfirmingAppointment = false

        // Switch view back to chatbot
        selectedSection = .chatbot
        selectedHistoryRoomId = nil // Deselect history room
    }

    func toggleScheduling(show: Bool) {
        print("Toggling scheduling UI: \(show)")
        if show {
            // Create BookingViewModel only when needed
            bookingViewModel = BookingViewModel()
        } else {
            bookingViewModel = nil // Release the booking view model
        }
        showSchedulingUI = show
    }

    func confirmAppointment() {
         guard let bookingVM = bookingViewModel, let doctor = bookingVM.selectedDoctor, let times = bookingVM.getFormattedAppointmentTimes(), canConfirmBooking else {
             errorMessage = "Please select a doctor, date, and time."
             print("❌ Appointment confirmation validation failed.")
             return
         }

         print("Confirming appointment for Dr. \(doctor.lastName) at \(times.0)")
         isConfirmingAppointment = true
         errorMessage = nil

         let requestData = CreateAppointmentRequest(
             doctorId: doctor.id,
             startTime: times.0,
             endTime: times.1,
             // Replace with actual URL logic if needed, or get from backend post-creation
             telemedicineUrl: "https://example.com/meeting/\(UUID().uuidString.prefix(8))"
         )

         Task {
             do {
                 let createdAppointment = try await networkManager.createAppointment(requestData: requestData)
                 print("✅ Appointment created successfully! ID: \(createdAppointment.id)")

                 // --- Success: Reset state ---
                 self.showSchedulingUI = false
                 self.bookingViewModel = nil // Clear booking VM
                 self.lastTriageAdvice = nil // Clear the prompt
                 // Optionally show a success message to the user

             } catch let error as NetworkError {
                 // --- UPDATED: Check error case, not direct equality ---
                 if case .unauthorized = error {
                     handleUnauthorized()
                 } else {
                     errorMessage = "Failed to book appointment: \(error.localizedDescription)"
                     print("❌ NetworkError creating appointment: \(error)")
                 }
             } catch {
                 errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                 print("❌ Unexpected error creating appointment: \(error)")
             }
             isConfirmingAppointment = false
         }
     }


    private func handleUnauthorized() {
        print("⚠️ Unauthorized access detected in ChatViewModel. Logging out.")
        errorMessage = "Your session has expired. Please log in again."
        appState.logout()
    }
}

// Enum for Chat Sections
enum ChatSection: String, CaseIterable, Identifiable {
    case chatbot = "Chatbot"
    case history = "See history"
    var id: String { self.rawValue }
}

// Helper extension to get first name from Keychain
extension KeychainHelper {
    // Assuming username is stored and used as first name, or store first name separately
    // during login/registration if available.
    func getFirstName() -> String? {
        // Use the *internal* account name defined in KeychainHelper
        return self.readData(service: KeychainHelper.authService, account: KeychainHelper.usernameAccount) // Use static properties
               .flatMap { String(data: $0, encoding: .utf8) }
    }
}
