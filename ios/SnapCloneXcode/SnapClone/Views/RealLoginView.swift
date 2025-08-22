import SwiftUI
import FirebaseAuth

struct RealLoginView: View {
    @EnvironmentObject var authViewModel: RealAuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var isSignUpMode: Bool = false
    @State private var showingForgotPassword: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to SnapClone")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if isSignUpMode {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
            }
            
            if authViewModel.isLoading {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        if isSignUpMode {
                            await authViewModel.signUp(email: email, password: password, username: username, displayName: displayName)
                        } else {
                            await authViewModel.signIn(email: email, password: password)
                        }
                    }
                }) {
                    Text(isSignUpMode ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(email.isEmpty || password.isEmpty || (isSignUpMode && (username.isEmpty || displayName.isEmpty)))
            }
            
            Button(action: {
                isSignUpMode.toggle()
            }) {
                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                showingForgotPassword = true
            }) {
                Text("Forgot Password?")
                    .foregroundColor(.gray)
            }
            
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
        .alert("Forgot Password", isPresented: $showingForgotPassword) {
            Button("OK") { }
        } message: {
            Text("Password reset functionality would go here")
        }
    }
}