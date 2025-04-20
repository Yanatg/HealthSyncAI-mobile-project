// HealthSyncAI-mobile-project/Views/Chat/ChatView.swift
// UPDATED FILE
import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject private var appState: AppState // Access AppState for user info

    // Use namespace for smooth transition with ScrollViewReader
    @Namespace var bottomID

    init(appState: AppState) {
        // Initialize the viewModel, passing the necessary appState
        _viewModel = StateObject(wrappedValue: ChatViewModel(appState: appState))
    }

    var body: some View {
        VStack(spacing: 0) { // No spacing for seamless layout
            // --- Header ---
             headerView

            // --- Main Content Area ---
            ZStack { // Layer booking UI over chat/history
                chatOrHistoryView

                if viewModel.showSchedulingUI, let bookingVM = viewModel.bookingViewModel {
                    BookingBoxView(viewModel: bookingVM, onBack: {
                        viewModel.toggleScheduling(show: false)
                    })
                    .background(Color(.systemBackground)) // Ensure it has a background
                    .transition(.move(edge: .bottom).combined(with: .opacity)) // Add animation
                    .zIndex(1) // Ensure booking view is on top
                }
            }
            .animation(.default, value: viewModel.showSchedulingUI) // Animate the appearance/disappearance

            // --- Footer Buttons (Conditionally shown) ---
             if !viewModel.showSchedulingUI {
                 footerButtonsView
             } else {
                 confirmButtonView // Show only confirm when scheduling
             }
        }
        .navigationTitle("Online Consult")
        .navigationBarTitleDisplayMode(.inline)
         // Hide the default back button if this view is pushed onto a NavigationView stack
         // .navigationBarBackButtonHidden(true)
         // Add toolbar items if needed (e.g., if not using a TabView)
         /*
         .toolbar {
             ToolbarItem(placement: .navigationBarLeading) {
                 // Custom back button or menu button
             }
         }
         */
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                // Use first name from viewModel
                Text("Hi, \(viewModel.userFirstName)!")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Text("Online Consult")
                    .font(.title2).bold()
            }
            Spacer()
            // Add any header icons if needed (e.g., profile)
        }
        .padding()
        .background(Color(.systemBackground)) // Match background
    }

    private var chatOrHistoryView: some View {
        VStack(spacing: 0) { // Use VStack to layout elements vertically
            // --- Consultation Info (Only in Chatbot section) ---
            if viewModel.selectedSection == .chatbot {
                consultationInfoView
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }

            // --- Section Picker & History Selector ---
             sectionSelectionView
                .padding(.horizontal)
                .padding(.bottom, 10)


            // --- Message Area ---
             messageAreaView
                .background(Color(.systemGray6)) // Background for the message area
                 .clipShape(RoundedRectangle(cornerRadius: 10)) // Optional rounded corners
                 .padding(.horizontal) // Padding for the message container


            // --- Input Area (Only in Chatbot section) ---
             if viewModel.selectedSection == .chatbot {
                 chatInputArea
                    .padding() // Padding around input field and button
            }
        }
    }

    private var consultationInfoView: some View {
         VStack(alignment: .leading, spacing: 5) {
            Text("Consultation Info")
                 .font(.headline)
            Text("Chat with our AI to get started or view history. The chatbot is for pre-scanning only. For accurate diagnosis, please consult a doctor.")
                 .font(.caption)
                 .foregroundColor(.secondary)
        }
    }

     private var sectionSelectionView: some View {
         HStack(alignment: .bottom) { // Align items to bottom
             // Section Picker
             VStack(alignment: .leading) {
                 Text("Section").font(.caption).foregroundColor(.secondary)
                 Picker("Section", selection: $viewModel.selectedSection) {
                     ForEach(ChatSection.allCases) { section in
                         Text(section.rawValue).tag(section)
                     }
                 }
                 .pickerStyle(.segmented)
                 .disabled(viewModel.showSchedulingUI) // Disable when booking
             }


             // History Room Selector (Conditional)
             if viewModel.selectedSection == .history && !viewModel.chatHistory.isEmpty {
                 VStack(alignment: .leading) {
                     Text("Chat Room").font(.caption).foregroundColor(.secondary)
                     Picker("Chat Room", selection: $viewModel.selectedHistoryRoomId) {
                         // Add a "Select..." option or handle nil selection
                         Text("Select...").tag(nil as Int?)

                         ForEach(viewModel.chatHistory) { room in
                             Text("Room \(room.roomNumber)").tag(room.roomNumber as Int?)
                         }
                     }
                     // Use .menu style for dropdown appearance if desired
                      .pickerStyle(.menu)
                      .disabled(viewModel.isLoadingHistory || viewModel.showSchedulingUI)
                 }
                 .frame(maxWidth: 150) // Limit width of history picker
             }
              Spacer() // Push pickers to the left
         }
     }

    private var messageAreaView: some View {
        ScrollViewReader { proxy in // Needed to scroll to bottom
            ScrollView {
                VStack(spacing: 8) { // Spacing between messages
                    if viewModel.selectedSection == .chatbot {
                        ForEach(viewModel.currentMessages) { msg in
                            ChatMessageView(message: msg)
                        }
                        // Display loading indicator for bot response
                        if viewModel.isLoadingResponse {
                            HStack {
                                LoadingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        // Display schedule prompt
                         if viewModel.showSchedulePrompt {
                             schedulePromptView
                                 .padding(.horizontal)
                         }
                    } else { // History Section
                         if viewModel.isLoadingHistory {
                             ProgressView("Loading History...")
                                 .padding()
                         } else if let error = viewModel.historyError {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding()
                         } else if viewModel.selectedHistoryRoomId == nil {
                             Text("Select a room to view its history.")
                                 .foregroundColor(.secondary)
                                 .padding()
                         } else if viewModel.selectedHistoryMessages.isEmpty {
                              Text("No messages in Room \(viewModel.selectedHistoryRoomId ?? 0).")
                                .foregroundColor(.secondary)
                                .padding()
                         } else {
                            ForEach(viewModel.selectedHistoryMessages) { msg in
                                ChatMessageView(message: msg)
                            }
                        }
                    }

                    // Empty view at the bottom to scroll to
                    Spacer().frame(height: 1).id(bottomID) // Give it minimal height
                }
                .padding(.vertical) // Padding top/bottom inside ScrollView
            }
            // --- UPDATED onChange ---
            .onChange(of: viewModel.currentMessages.count) { // Zero-parameter action
                withAnimation {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.selectedHistoryRoomId) { // Zero-parameter action
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Slight delay to allow rendering
                      withAnimation {
                          proxy.scrollTo(bottomID, anchor: .bottom)
                      }
                 }
             }
             .onAppear { // Scroll on initial appear
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                     // Ensure scrolling happens even if count doesn't change initially
                     // but selection does, or just on first load.
                     withAnimation {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                     }
                  }
             }
        }
    }

    private var schedulePromptView: some View {
         HStack {
             Image(systemName: "exclamationmark.bubble.fill")
                 .foregroundColor(.orange)
             Text("We recommend scheduling an appointment.")
             Button("Schedule Now") {
                 viewModel.toggleScheduling(show: true)
             }
             // --- UPDATED: Manual Styling for Link-like Button ---
             .foregroundColor(.accentColor) // Use accent color for link look
             // Remove .buttonStyle(.link)
             Spacer()
         }
         .padding(10)
         .background(Color.orange.opacity(0.15))
         .cornerRadius(8)
         .font(.footnote)
     }


    private var chatInputArea: some View {
        HStack(spacing: 10) {
            TextField("Type a message...", text: $viewModel.currentInput)
                .textFieldStyle(.plain) // Use plain style for custom background
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                 .background(Color(.systemBackground)) // Or systemGray6
                .cornerRadius(18) // More rounded input field
                 .overlay(
                     RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                 )
                 .onSubmit(viewModel.sendMessage) // Send on return key

            Button(action: viewModel.sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.canSendMessage ? .accentColor : .gray)
            }
            .disabled(!viewModel.canSendMessage)
        }
    }

    private var footerButtonsView: some View {
         HStack(spacing: 15) {
             // New Chat Button
             Button("New Chat") {
                 viewModel.startNewChat()
             }
             .buttonStyle(.bordered) // Use bordered style
             .disabled(!viewModel.canStartNewChat)

             Spacer() // Pushes buttons to edges

             // Schedule Appointment Button
             Button("Schedule Appointment") {
                 viewModel.toggleScheduling(show: true)
             }
             .buttonStyle(.borderedProminent) // Prominent style for primary action
             .disabled(!viewModel.canScheduleAppointment)
         }
         .padding()
         .background(.thinMaterial) // Add a material background to the footer
     }

     private var confirmButtonView: some View {
          HStack {
              Spacer() // Push confirm button to the right

              Button {
                  viewModel.confirmAppointment()
              } label: {
                  HStack {
                      if viewModel.isConfirmingAppointment {
                          ProgressView().tint(.white)
                      }
                      Text("Confirm Appointment")
                  }
                  .padding(.horizontal)
              }
              .buttonStyle(.borderedProminent)
              .disabled(!viewModel.canConfirmBooking)
          }
          .padding()
          .background(.thinMaterial)
      }

}

// MARK: - Preview
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
         // Create a dummy AppState for preview
         let appState = AppState()
         // Simulate being logged in for the preview
         appState.isLoggedIn = true
         appState.userRole = .patient
         appState.userId = 123
         // KeychainHelper.standard.saveAuthToken("dummy_token_for_preview") // No network calls on init in preview

         return NavigationView { // Embed in NavigationView for Title
             ChatView(appState: appState)
                 .environmentObject(appState) // Provide the environment object
         }
    }
}
