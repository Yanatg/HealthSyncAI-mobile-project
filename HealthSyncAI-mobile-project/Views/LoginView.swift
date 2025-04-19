// HealthSyncAI-mobile-project/Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()

    // Bindings to the parent view's (App) state
    @Binding var isLoggedIn: Bool
    // **** CHANGE BINDING NAME HERE ****
    @Binding var userRole: UserRole? // Renamed from loggedInRole to match App's state variable

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
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(8)
            }

            // --- Error Message ---
            if let error = viewModel.errorMessage, !viewModel.isLoading {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }

            // --- Login Button ---
            Button {
                viewModel.login()
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
                .background(viewModel.isLoading ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            .disabled(viewModel.isLoading)

            Spacer()

            Button("Don't have an account? Sign Up") {
                print("Navigate to Sign Up")
            }
            .padding(.bottom)

        }
        .padding(.horizontal, 30)
        .onChange(of: viewModel.loggedInUserRole) { newRole in
            if let validRole = newRole {
                isLoggedIn = true
                // **** UPDATE ASSIGNMENT HERE ****
                userRole = validRole // Assign to the renamed binding variable
                print("LoginView: Role changed detected. Updating App state. Role: \(validRole.rawValue)")
            }
        }
    }
}

// --- Preview Provider ---
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        // **** UPDATE PREVIEW CALL SITE ****
        LoginView(isLoggedIn: .constant(false), userRole: .constant(nil)) // Use userRole here too
    }
}
