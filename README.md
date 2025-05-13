
## 🖼️ Screenshots & GIFs

![1](https://github.com/user-attachments/assets/819ca63b-9ae3-4f59-b6be-1ebaa9126e28)
![2](https://github.com/user-attachments/assets/68371033-5288-4182-973f-5ff96f736564)


## ⚙️ Setup & Installation

### Prerequisites:
1.  **Xcode:** Latest version recommended (compatible with Swift 5.x and iOS 15+).
2.  **Backend Server:** A running instance of the HealthSyncAI backend.
    *   The mobile application is pre-configured to connect to `http://localhost:8000`.

### Configuration:
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Yanatg/HealthSyncAI-mobile-project
    cd HealthSyncAI-mobile-project
    ```
2.  **Open in Xcode:** Open the `HealthSyncAI-mobile-project.xcodeproj` file (or the parent folder).
3.  **Backend URL:**
    *   If your backend is running on a different address or port, update the `baseURL` constant in `Services/NetworkManager.swift`:
        ```swift
        // Services/NetworkManager.swift
        // private let baseURL: URL?
        // ...
        // let urlString = "http://your-backend-address:port" // Modify this line
        ```
4.  **API Endpoints:** Ensure the API endpoints defined in `NetworkManager.swift` (e.g., `/api/auth/login`, `/api/appointment/my-appointments`) match your backend routes.
5.  **Build & Run:** Select a target simulator or a connected iOS device and run the project from Xcode.

## 🔑 Key Files to Note

*   **`HealthSyncAI_mobile_projectApp.swift`**: The main entry point of the application. It initializes the `AppState` and sets up the root view hierarchy, switching between the `SplashScreenView`, `LoginView`, and the main content (Patient TabView or Doctor View) based on the authentication state.
*   **`Managers/AppState.swift`**: A crucial `ObservableObject` that manages the global application state, including `isLoggedIn`, `userRole`, and `userId`. This state drives the UI flow throughout the app.
*   **`Services/NetworkManager.swift`**: This singleton class is responsible for all network communication with the backend API. It includes generic request functions and specific API call implementations for various features like authentication, fetching appointments, health records, chat, and statistics.
*   **`Utils/KeychainHelper.swift`**: Provides a secure way to store and retrieve sensitive user data, such as authentication tokens and user IDs, using the iOS Keychain.
*   **`ViewModels/AuthViewModel.swift`**: Manages the state and logic for both user login and registration, including form validation and interaction with `NetworkManager`.
*   **`ViewModels/ChatViewModel.swift`**: Handles the complex logic for the AI chatbot, including sending messages, managing chat history, and coordinating with `BookingViewModel` for appointment scheduling.
*   **`Views/Chat/ChatView.swift` & `Views/Chat/BookingBoxView.swift`**: Demonstrate how SwiftUI can be used to build interactive and dynamic user interfaces for complex features.
*   **Model files (e.g., `Models/Appointment.swift`, `Models/HealthRecord.swift`)**: Show the use of `Codable` and `CodingKeys` for mapping JSON data from the API (often `snake_case`) to Swift properties (`camelCase`).

## 💡 Future Enhancements (Potential)

*   **Real-time Chat:** Implement WebSockets or similar for live chat features.
*   **Push Notifications:** For appointment reminders, new messages, or important updates.
*   **HealthKit Integration:** Allow patients to sync data from Apple Health.
*   **Doctor Profiles & Search:** More detailed doctor profiles and advanced search/filter capabilities.
*   **UI/UX Refinements:** Continuous improvements to the user interface and experience.
*   **Offline Support:** Basic caching or offline access for certain data.
*   **Localization:** Support for multiple languages.
*   **Enhanced AI:** More sophisticated AI models for triage and health advice.

## 🤝 Contributing

Contributions are welcome! If you'd like to contribute, please fork the repository and submit a pull request. For major changes, please open an issue first to discuss what you would like to change.

---

Thank you for checking out HealthSyncAI Mobile Project! We hope it serves as a useful example of a modern SwiftUI application.
