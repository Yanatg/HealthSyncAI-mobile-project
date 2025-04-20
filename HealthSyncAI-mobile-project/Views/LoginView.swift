// HealthSyncAI-mobile-project/Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    // Use the single AuthViewModel, but this view focuses on LOGIN properties
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                Text("Welcome Back!")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                // --- Role Selection (Uses selectedLoginRole) ---
                Picker("Login As", selection: $viewModel.selectedLoginRole) { // Bind to login role
                    ForEach(UserRole.allCases) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.segmented)

                // --- Input Fields (Use loginUsername, loginPassword) ---
                VStack(spacing: 15) {
                    TextField("Username", text: $viewModel.loginUsername) // Bind to login username
                        .keyboardType(.default)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    SecureField("Password", text: $viewModel.loginPassword) // Bind to login password
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }

                // --- Error Message ---
                if let error = viewModel.errorMessage, !viewModel.isLoading {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // --- Login Button ---
                Button {
                    // Clear registration fields before login attempt (optional, good practice)
                    // viewModel.clearRegistrationFields()
                    viewModel.login(appState: appState)
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                             // Display the selected LOGIN role
                            Text("Login as \(viewModel.selectedLoginRole.rawValue)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(viewModel.isLoading ? Color.gray : Color.accentColor)
                    .cornerRadius(10)
                }
                // Disable based on LOGIN fields
                .disabled(viewModel.isLoading || viewModel.loginUsername.isEmpty || viewModel.loginPassword.isEmpty)

                Spacer()

                // --- Sign Up Navigation ---
                NavigationLink {
                    // Pass the SAME viewModel instance to RegistrationView
                    RegistrationView(viewModel: viewModel)
                } label: {
                    Text("Don't have an account? Sign Up")
                }
                .padding(.bottom)
            }
            .padding(.horizontal, 30)
            .navigationBarHidden(true)
            .onAppear {
                // Clear registration fields when returning to login (optional)
                // viewModel.clearRegistrationFields()
                // Clear any potential error message from registration attempt
                viewModel.errorMessage = nil
            }
        }
        // Keep AppState injection
        .environmentObject(appState)
    }
}

// Preview requires AppState
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
    }
}
