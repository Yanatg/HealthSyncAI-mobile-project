// HealthSyncAI-mobile-project/Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var appState: AppState // Get AppState from environment

    // REMOVE: @Binding var isLoggedIn: Bool
    // REMOVE: @Binding var userRole: UserRole?

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome Back!")
                .font(.largeTitle)
                .fontWeight(.semibold)

            // --- Role Selection ---
            Picker("Login As", selection: $viewModel.selectedRole) {
                ForEach(UserRole.allCases) { role in
                    Text(role.rawValue).tag(role)
                }
            }
            .pickerStyle(.segmented)

            // --- Input Fields ---
            VStack(spacing: 15) {
                TextField("Username", text: $viewModel.username)
                    .keyboardType(.default) // Use default, allow any username chars
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true) // Often good for usernames
                    .padding()
                    .background(Color(.secondarySystemBackground)) // Use system color
                    .cornerRadius(8)

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }

            // --- Error Message ---
            // Show error message only if not loading
            if let error = viewModel.errorMessage, !viewModel.isLoading {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal) // Add horizontal padding
                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
            }

            // --- Login Button ---
            Button {
                // Pass the appState to the login function
                viewModel.login(appState: appState)
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Login as \(viewModel.selectedRole.rawValue)")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(viewModel.isLoading ? Color.gray : Color.accentColor) // Use AccentColor
                .cornerRadius(10)
            }
            .disabled(viewModel.isLoading || viewModel.username.isEmpty || viewModel.password.isEmpty) // Also disable if fields are empty

            Spacer()

            // --- Sign Up Navigation (Placeholder) ---
            Button("Don't have an account? Sign Up") {
                // TODO: Implement navigation to a RegistrationView
                print("Navigate to Sign Up (Not Implemented)")
            }
            .padding(.bottom)

        }
        .padding(.horizontal, 30)
        // REMOVE: .onChange modifier - UI now reacts directly to appState changes
    }
}

// Preview needs AppState injected
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState()) // Provide a dummy AppState for preview
    }
}
