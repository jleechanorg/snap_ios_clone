import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authService = FirebaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("SnapClone")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.bottom, 30)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .accessibilityIdentifier("emailField")
                    
                    if isSignUp {
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .accessibilityIdentifier("usernameField")
                    }
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityIdentifier("passwordField")
                }
                .padding(.horizontal)
                
                if let authError = authService.error {
                    Text(authError)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityIdentifier("errorMessage")
                }
                
                Button(action: authenticate) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        }
                        Text(isSignUp ? "Sign Up" : "Login")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || authService.isLoading)
                .opacity((!isFormValid || authService.isLoading) ? 0.6 : 1.0)
                .padding(.horizontal)
                .accessibilityIdentifier("authButton")
                
                Button(action: toggleAuthMode) {
                    Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                        .foregroundColor(.yellow)
                        .underline()
                }
                .accessibilityIdentifier("toggleAuthButton")
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = !email.isEmpty && email.contains("@")
        let passwordValid = password.count >= 6
        let usernameValid = isSignUp ? !username.isEmpty : true
        
        return emailValid && passwordValid && usernameValid
    }
    
    private func authenticate() {
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                print("Authentication error: \(error)")
            }
        }
    }
    
    private func toggleAuthMode() {
        isSignUp.toggle()
        authService.clearError()
    }
}

#Preview {
    AuthenticationView()
}