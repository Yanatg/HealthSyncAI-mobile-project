import Foundation
import Combine
import SwiftUI // For Color and Date

@MainActor // Ensure UI updates happen on the main thread
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

    // --- Booking Confirmation State (Managed by Combine) ---
    @Published var canConfirmBooking: Bool = false // <<< Now @Published, updated by listener

    // --- Dependencies ---
    @Published var userFirstName: String = "" // Display name
    private let networkManager = NetworkManager.shared
    private let appState: AppState // Needs AppState for auth status/logout
    private let keychainHelper = KeychainHelper.standard

    // --- Combine Subscription ---
    private var bookingStateCancellable: AnyCancellable? // <<< Stores the subscription

    // Keep track of the room number for the *current* active chat session
    private var activeChatRoomNumber: Int? = nil

    // --- Initialization ---
    init(appState: AppState) {
        self.appState = appState
        self.userFirstName = keychainHelper.getFirstName() ?? "there"
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
                ]
            }
    }

    var canSendMessage: Bool {
        !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoadingResponse && !isConfirmingAppointment && !showSchedulingUI
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

    // Note: 'canConfirmBooking' is now a @Published var updated by the listener

    // --- Actions ---

    func selectSection(_ section: ChatSection) {
        selectedSection = section
        if section == .history && selectedHistoryRoomId == nil {
            selectedHistoryRoomId = chatHistory.first?.roomNumber
        }
        lastTriageAdvice = nil
        errorMessage = nil
        // If switching away from chatbot while scheduling UI is open, close it
        if section != .chatbot && showSchedulingUI {
             toggleScheduling(show: false) // Close booking if switching section
        }
    }

    func fetchHistory() {
        guard !isLoadingHistory else { return }
        print("Fetching chat history...")
        isLoadingHistory = true
        historyError = nil

        Task {
            do {
                let history = try await networkManager.fetchChatHistory()
                self.chatHistory = history.sorted { $0.roomNumber > $1.roomNumber }

                if let highestRoomNum = self.chatHistory.first?.roomNumber {
                    self.currentRoomNumber = highestRoomNum + 1
                } else {
                    self.currentRoomNumber = 1
                }
                print("✅ Fetched \(self.chatHistory.count) chat rooms. Next room number: \(self.currentRoomNumber ?? 0)")

                if self.selectedSection == .history && self.selectedHistoryRoomId == nil {
                    self.selectedHistoryRoomId = self.chatHistory.first?.roomNumber
                }

            } catch let error as NetworkError {
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
        currentInput = ""

        currentMessages.append(DisplayMessage(sender: .user, text: messageText))
        isLoadingResponse = true
        errorMessage = nil
        lastTriageAdvice = nil

        if activeChatRoomNumber == nil {
            activeChatRoomNumber = currentRoomNumber
        }

        print("Sending message: '\(messageText)' to room: \(activeChatRoomNumber ?? -1)")
        let requestBody = ChatSymptomRequest(symptomText: messageText, roomNumber: activeChatRoomNumber)

        Task {
            do {
                let response = try await networkManager.sendChatMessage(message: requestBody)
                currentMessages.append(DisplayMessage(sender: .bot, text: response.analysis ?? "Sorry, I couldn't process that."))

                if let advice = response.triageAdvice, !advice.isEmpty {
                    self.lastTriageAdvice = advice
                    print("ℹ️ Received triage advice: \(advice)")
                }

                // Handle room number increment and history refresh
                if requestBody.roomNumber == currentRoomNumber {
                     let roomExisted = chatHistory.contains { $0.roomNumber == currentRoomNumber }
                     if !roomExisted {
                         // Refetch history to include the new room in the list.
                         // This is simpler than manually inserting.
                         fetchHistory()
                     }
                     // Increment only after the *first* successful message of a new chat session
                     currentRoomNumber = (currentRoomNumber ?? 0) + 1
                 }

            } catch let error as NetworkError {
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

        currentMessages = [DisplayMessage(sender: .bot, text: "Hello, how can I help you?")]
        currentInput = ""
        isLoadingResponse = false
        lastTriageAdvice = nil
        errorMessage = nil
        activeChatRoomNumber = nil

        // Cancel listener and reset booking state if user starts a new chat
        toggleScheduling(show: false) // This also handles cancelling the listener

        selectedSection = .chatbot
        selectedHistoryRoomId = nil
    }

    // --- UPDATED: Includes listener setup/cancellation ---
    func toggleScheduling(show: Bool) {
        print("Toggling scheduling UI: \(show)")
        if show {
            // Ensure we are in the chatbot section
            guard selectedSection == .chatbot else {
                print("⚠️ Cannot open scheduling UI from outside chatbot section.")
                return
            }
            // Create BookingViewModel only when needed
            if bookingViewModel == nil {
                bookingViewModel = BookingViewModel()
                setupBookingViewModelListener() // <<< Start listening when VM is created
            }
        } else {
            bookingStateCancellable?.cancel() // <<< Stop listening
            bookingViewModel = nil // Release the booking view model
            canConfirmBooking = false // <<< Reset confirmation state explicitly
            isConfirmingAppointment = false // Reset confirmation spinner state
        }
        // Update the UI visibility state *after* setting up/tearing down
        showSchedulingUI = show
    }

    // --- NEW: Listener Setup ---
    private func setupBookingViewModelListener() {
        // Ensure we have a VM to listen to
        guard let bookingVM = bookingViewModel else {
            print("❌ Cannot setup listener: BookingViewModel is nil.")
            canConfirmBooking = false // Cannot confirm if no VM exists
            return
        }

        print("🎧 Setting up listener for BookingViewModel state changes...")

        // Cancel any previous subscription to avoid leaks or duplicate updates
        bookingStateCancellable?.cancel()

        // Create the pipeline to observe relevant properties in BookingViewModel
        bookingStateCancellable = bookingVM.$selectedDate // Listen to date
            .combineLatest(bookingVM.$selectedTimeSlot, bookingVM.$selectedDoctor, bookingVM.$isBooking) // Listen to time, doctor, and booking status
            .map { date, timeSlot, doctor, isBookingInProgress -> Bool in
                // Logic: Can confirm only if a date, timeslot, AND doctor are selected, AND not currently booking
                let canBook = timeSlot != nil && doctor != nil && !isBookingInProgress
                print("⚙️ Combine Check: Date=\(date), Time=\(String(describing: timeSlot)), Doctor=\(String(describing: doctor?.id)), IsBooking=\(isBookingInProgress) -> CanConfirm: \(canBook)") // Debugging
                return canBook
            }
            .receive(on: DispatchQueue.main) // Ensure the update happens on the main thread
            .assign(to: \.canConfirmBooking, on: self) // Assign the result directly to canConfirmBooking
    }
    // --- End NEW Listener Setup ---

    func confirmAppointment() {
         // Use the @Published canConfirmBooking which is updated by the listener
         guard canConfirmBooking, let bookingVM = bookingViewModel else {
             errorMessage = "Please ensure a doctor, date, and time slot are selected."
             print("❌ [ChatVM] Appointment confirmation validation failed (canConfirmBooking=\(canConfirmBooking), bookingVM exists=\(bookingViewModel != nil)).")
             return
         }
         // Now we are sure bookingVM is non-nil because canConfirmBooking depends on it
         guard let doctor = bookingVM.selectedDoctor,
               let times = bookingVM.getFormattedAppointmentTimes() else {
             errorMessage = "Internal error: Missing booking details."
             print("❌ [ChatVM] Appointment confirmation failed: Missing doctor or formatted times despite canConfirmBooking being true.")
             return
         }

         // Check if already confirming (ChatViewModel still manages this temporary UI state)
         guard !isConfirmingAppointment else { return }

         print("▶️ [ChatVM] Initiating appointment confirmation...")
         isConfirmingAppointment = true // Show spinner in ChatView
         errorMessage = nil

         let requestData = CreateAppointmentRequest(
             doctorId: doctor.id,
             startTime: times.0,
             endTime: times.1,
             telemedicineUrl: "https://example.com/meeting/\(UUID().uuidString.prefix(8))" // Adjust as needed
         )

         Task {
            var bookingSuccess = false
             do {
                 // --- CALL BookingViewModel's performBooking ---
                 let createdAppointment = try await bookingVM.performBooking(requestData: requestData)
                 // --------------------------------------------
                 print("✅ [ChatVM] Appointment creation delegated successfully! ID: \(createdAppointment.id)")
                 bookingSuccess = true

             } catch let error as NetworkError {
                 if case .unauthorized = error {
                     handleUnauthorized()
                 } else {
                     errorMessage = "Failed to book appointment: \(error.localizedDescription)"
                     print("❌ [ChatVM] NetworkError during booking delegation: \(error)")
                 }
             } catch {
                 errorMessage = "An unexpected error occurred during booking: \(error.localizedDescription)"
                 print("❌ [ChatVM] Unexpected error during booking delegation: \(error)")
             }

             // --- Reset state (ChatViewModel's responsibility for UI flow) ---
             // Check if task was cancelled or if logout occurred
             if !Task.isCancelled && !(errorMessage?.contains("session has expired") ?? false) {
                 self.isConfirmingAppointment = false // Hide ChatView spinner

                 if bookingSuccess {
                     // Success: Hide booking UI & clear related state in ChatViewModel
                     self.toggleScheduling(show: false)
                     self.lastTriageAdvice = nil // Clear the schedule prompt
                     // Consider showing a confirmation message/alert here
                     print("🎉 [ChatVM] Booking flow completed successfully.")
                 } else {
                     // Failure: Keep booking UI open so user can retry or change details
                     // Error message should already be set
                     print("⚠️ [ChatVM] Booking flow failed. Booking UI remains open.")
                 }
             }
         }
     }


    private func handleUnauthorized() {
        print("⚠️ Unauthorized access detected in ChatViewModel. Logging out.")
        errorMessage = "Your session has expired. Please log in again."
        bookingStateCancellable?.cancel() // Cancel listener on logout
        appState.logout()
        // Resetting states like showSchedulingUI happens implicitly via AppState change or could be done here if needed
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
        return self.readData(service: KeychainHelper.authService, account: KeychainHelper.usernameAccount)
               .flatMap { String(data: $0, encoding: .utf8) }
    }
}
