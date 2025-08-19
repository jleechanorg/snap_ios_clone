import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.9, green: 0.9, blue: 0.0),
                        Color(red: 1.0, green: 0.8, blue: 0.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacing
                        Spacer()
                            .frame(height: max(50, (geometry.size.height - keyboardHeight) * 0.1))
                        
                        // Logo and title
                        VStack(spacing: 20) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            
                            Text("SnapClone")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        }
                        .padding(.bottom, 40)
                        
                        // Authentication Form
                        VStack(spacing: 20) {
                            if authViewModel.isSignUpMode {
                                SignUpForm()
                            } else {
                                SignInForm()
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                            .frame(height: max(50, (geometry.size.height - keyboardHeight) * 0.1))
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                keyboardHeight = keyboardFrame.cgRectValue.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK") {
                authViewModel.dismissError()
            }
        } message: {
            Text(authViewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $authViewModel.showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

struct SignInForm: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Email field
            CustomTextField(
                text: $authViewModel.email,
                placeholder: "Email",
                keyboardType: .emailAddress,
                isValid: authViewModel.isEmailValid
            )
            
            // Password field
            CustomSecureField(
                text: $authViewModel.password,
                placeholder: "Password",
                isValid: authViewModel.isPasswordValid
            )
            
            // Forgot password
            HStack {
                Spacer()
                Button("Forgot Password?") {
                    authViewModel.showForgotPasswordSheet()
                }
                .font(.caption)
                .foregroundColor(.white)
            }
            
            // Sign in button
            Button(action: {
                Task {
                    await authViewModel.signIn()
                }
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    }
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(authViewModel.canSignIn ? Color.white : Color.gray.opacity(0.3))
                .foregroundColor(authViewModel.canSignIn ? .black : .white)
                .cornerRadius(25)
            }
            .disabled(!authViewModel.canSignIn)
            
            // Switch to sign up
            Button(action: {
                authViewModel.toggleSignUpMode()
            }) {
                Text("Don't have an account? Sign Up")
                    .font(.caption)
                    .foregroundColor(.white)
                    .underline()
            }
            .padding(.top, 10)
        }
    }
}

struct SignUpForm: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Email field
            CustomTextField(
                text: $authViewModel.email,
                placeholder: "Email",
                keyboardType: .emailAddress,
                isValid: authViewModel.isEmailValid
            )
            
            // Username field
            CustomTextField(
                text: $authViewModel.username,
                placeholder: "Username",
                keyboardType: .default,
                isValid: authViewModel.isUsernameValid
            )
            
            // Display name field
            CustomTextField(
                text: $authViewModel.displayName,
                placeholder: "Display Name (Optional)",
                keyboardType: .default
            )
            
            // Password field
            CustomSecureField(
                text: $authViewModel.password,
                placeholder: "Password",
                isValid: authViewModel.isPasswordValid
            )
            
            // Confirm password field
            CustomSecureField(
                text: $authViewModel.confirmPassword,
                placeholder: "Confirm Password",
                isValid: authViewModel.passwordsMatch
            )
            
            // Validation messages
            VStack(alignment: .leading, spacing: 4) {
                if !authViewModel.isEmailValid && !authViewModel.email.isEmpty {
                    ValidationMessage(text: "Please enter a valid email")
                }
                if !authViewModel.isUsernameValid && !authViewModel.username.isEmpty {
                    ValidationMessage(text: "Username must be 3-20 characters (letters, numbers, underscore)")
                }
                if !authViewModel.isPasswordValid && !authViewModel.password.isEmpty {
                    ValidationMessage(text: "Password must be at least 6 characters")
                }
                if !authViewModel.passwordsMatch && !authViewModel.confirmPassword.isEmpty {
                    ValidationMessage(text: "Passwords do not match")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Sign up button
            Button(action: {
                Task {
                    await authViewModel.signUp()
                }
            }) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            .scaleEffect(0.8)
                    }
                    Text("Sign Up")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(authViewModel.canSignUp ? Color.white : Color.gray.opacity(0.3))
                .foregroundColor(authViewModel.canSignUp ? .black : .white)
                .cornerRadius(25)
            }
            .disabled(!authViewModel.canSignUp)
            
            // Switch to sign in
            Button(action: {
                authViewModel.toggleSignUpMode()
            }) {
                Text("Already have an account? Sign In")
                    .font(.caption)
                    .foregroundColor(.white)
                    .underline()
            }
            .padding(.top, 10)
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                CustomTextField(
                    text: $authViewModel.email,
                    placeholder: "Email",
                    keyboardType: .emailAddress,
                    isValid: authViewModel.isEmailValid
                )
                
                Button(action: {
                    Task {
                        await authViewModel.resetPassword()
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Send Reset Link")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(authViewModel.canResetPassword ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .disabled(!authViewModel.canResetPassword)
                
                Spacer()
            }
            .padding(30)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Components

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    var isValid: Bool = true
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isValid ? Color.clear : Color.red, lineWidth: 2)
            )
    }
}

struct CustomSecureField: View {
    @Binding var text: String
    let placeholder: String
    var isValid: Bool = true
    @State private var isSecure = true
    
    var body: some View {
        HStack {
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .autocapitalization(.none)
            .autocorrectionDisabled()
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isValid ? Color.clear : Color.red, lineWidth: 2)
        )
    }
}

struct ValidationMessage: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationViewModel())
}