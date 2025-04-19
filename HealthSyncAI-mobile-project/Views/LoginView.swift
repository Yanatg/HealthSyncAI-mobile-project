// Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    // Create and own the ViewModel instance for this view
    @StateObject private var viewModel = AuthViewModel()

    // You might pass this binding from a parent view to know when login succeeds
    @Binding var isLoggedIn: Bool
    @Binding var loggedInRole: UserRole? // Pass role back up

    var body: some View {
        VStack(spacing: 20) { // Add overall spacing
            Spacer() // Push content towards the center/top

            Text("Welcome Back!")
                .font(.largeTitle)
                .fontWeight(.semibold)

            // --- Role Selection ---
            Picker("Login As", selection: $viewModel.selectedRole) {
                ForEach(UserRole.allCases) { role in
                    Text(role.rawValue).tag(role)
                }
            }
            .pickerStyle(.segmented) // Common style for this type of selection

            // --- Input Fields ---
            VStack(spacing: 15) {
                TextField("Username", text: $viewModel.username)
                    .keyboardType(.emailAddress) // Or .default
                    .textContentType(.username) // Helps with autofill
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground)) // Subtle background
                    .cornerRadius(8)

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password) // Helps with autofill
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }

            // --- Error Message ---
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }

            // --- Login Button ---
            Button {
                viewModel.login()
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white) // Make spinner white
                    } else {
                        Text("Login as \(viewModel.selectedRole.rawValue)")
                    }
                }
                .frame(maxWidth: .infinity) // Make button wide
                .padding()
                .foregroundColor(.white)
                .background(viewModel.isLoading ? Color.gray : Color.blue) // Change color when loading
                .cornerRadius(10)
            }
            .disabled(viewModel.isLoading) // Disable button while loading

            Spacer() // Push content towards the center/bottom

            // Optional: Add Sign Up button/link
            Button("Don't have an account? Sign Up") {
                // Handle navigation to Sign Up view
                print("Navigate to Sign Up")
            }
            .padding(.bottom) // Add some bottom padding

        }
        .padding(.horizontal, 30) // Add horizontal padding to the main VStack
        .onChange(of: viewModel.isAuthenticated) { authenticated in
             // When viewModel.isAuthenticated changes (due to successful login),
             // update the @Binding passed from the parent view.
             if authenticated {
                 isLoggedIn = true
                 loggedInRole = viewModel.loggedInUserRole
             }
         }
        .alert("Login Error", isPresented: .constant(viewModel.errorMessage != nil && !viewModel.isLoading)) {
            // Alternative way to show errors using .alert modifier
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
}

// --- Preview Provider ---
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide dummy bindings for the preview
        LoginView(isLoggedIn: .constant(false), loggedInRole: .constant(nil))
    }
}
