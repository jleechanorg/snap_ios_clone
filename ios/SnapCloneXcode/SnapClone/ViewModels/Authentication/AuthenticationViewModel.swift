import Foundation
import SwiftUI
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Form fields
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var username = ""
    @Published var displayName = ""
    
    // Form validation
    @Published var isEmailValid = true
    @Published var isPasswordValid = true
    @Published var isUsernameValid = true
    @Published var passwordsMatch = true
    
    // UI State
    @Published var isSignUpMode = false
    @Published var showForgotPassword = false
    
    // MARK: - Dependencies  
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupValidation()
        // Demo mode - auto-authenticate after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn() async {
        guard validateSignInForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            // User will be set by auth state listener
            clearForm()
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard validateSignUpForm() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signUp(
                email: email,
                password: password,
                username: username,
                displayName: displayName.isEmpty ? username : displayName
            )
            // User will be set by auth state listener
            clearForm()
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        
        do {
            try await authService.signOut()
            // Auth state will be cleared by listener
            clearForm()
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func resetPassword() async {
        guard !email.isEmpty, isValidEmail(email) else {
            showErrorMessage("Please enter a valid email address")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
            showErrorMessage("Password reset email sent successfully", isError: false)
            showForgotPassword = false
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            showErrorMessage("Unable to access presenting view controller")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            let user = gidSignInResult.user
            guard let idToken = user.idToken?.tokenString else {
                showErrorMessage("Unable to get ID token")
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Create user profile in Firestore if needed
            let firebaseUser = authResult.user
            let userProfile = User(
                id: firebaseUser.uid,
                username: firebaseUser.email?.components(separatedBy: "@").first ?? "user",
                email: firebaseUser.email ?? "",
                displayName: firebaseUser.displayName ?? "",
                profileImageURL: firebaseUser.photoURL?.absoluteString ?? "",
                createdAt: Date()
            )
            
            try await authService.updateUserProfile(userProfile)
            // User will be set by auth state listener
            
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func checkAuthenticationStatus() {
        if let firebaseUser = authService.getCurrentUser() {
            Task {
                do {
                    if let user = try await authService.fetchUserProfile(by: firebaseUser.displayName ?? "") {
                        currentUser = user
                        isAuthenticated = true
                    } else {
                        // User profile doesn't exist, sign out
                        try? await authService.signOut()
                        isAuthenticated = false
                    }
                } catch {
                    // User profile doesn't exist, sign out
                    try? await authService.signOut()
                    isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Form Validation
    
    private func setupValidation() {
        // Email validation
        $email
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .map(isValidEmail)
            .assign(to: &$isEmailValid)
        
        // Password validation
        $password
            .map { $0.count >= 6 }
            .assign(to: &$isPasswordValid)
        
        // Username validation
        $username
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .map(isValidUsername)
            .assign(to: &$isUsernameValid)
        
        // Password match validation
        Publishers.CombineLatest($password, $confirmPassword)
            .map { password, confirmPassword in
                confirmPassword.isEmpty || password == confirmPassword
            }
            .assign(to: &$passwordsMatch)
    }
    
    private func validateSignInForm() -> Bool {
        guard !email.isEmpty else {
            showErrorMessage("Email is required")
            return false
        }
        
        guard isValidEmail(email) else {
            showErrorMessage("Please enter a valid email address")
            return false
        }
        
        guard !password.isEmpty else {
            showErrorMessage("Password is required")
            return false
        }
        
        return true
    }
    
    private func validateSignUpForm() -> Bool {
        guard validateSignInForm() else { return false }
        
        guard !username.isEmpty else {
            showErrorMessage("Username is required")
            return false
        }
        
        guard isValidUsername(username) else {
            showErrorMessage("Username must be 3-20 characters and contain only letters, numbers, and underscores")
            return false
        }
        
        guard password.count >= 6 else {
            showErrorMessage("Password must be at least 6 characters")
            return false
        }
        
        guard password == confirmPassword else {
            showErrorMessage("Passwords do not match")
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        return NSPredicate(format: "SELF MATCHES %@", usernameRegex).evaluate(with: username)
    }
    
    // MARK: - Helper Methods
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        username = ""
        displayName = ""
        errorMessage = nil
        showError = false
    }
    
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthError {
            showErrorMessage(authError.localizedDescription)
        } else {
            showErrorMessage("An unexpected error occurred. Please try again.")
        }
    }
    
    private func showErrorMessage(_ message: String, isError: Bool = true) {
        errorMessage = message
        showError = isError
        
        if !isError {
            // Auto-hide success messages
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.errorMessage = nil
                self.showError = false
            }
        }
    }
    
    private func listenToAuthChanges() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                if user == nil {
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty && isEmailValid && !isLoading
    }
    
    var canSignUp: Bool {
        !email.isEmpty && !password.isEmpty && !username.isEmpty &&
        isEmailValid && isPasswordValid && isUsernameValid && passwordsMatch && !isLoading
    }
    
    var canResetPassword: Bool {
        !email.isEmpty && isEmailValid && !isLoading
    }
    
    // MARK: - UI Actions
    
    func toggleSignUpMode() {
        isSignUpMode.toggle()
        clearForm()
    }
    
    func showForgotPasswordSheet() {
        showForgotPassword = true
    }
    
    func dismissError() {
        errorMessage = nil
        showError = false
    }
}