import SwiftUI
import Firebase
import GoogleSignIn
import CocoaLumberjack

struct LoginScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var commonViewModel : CommonViewModel
    @StateObject var scanCollectionViewModel = ScanCollectionViewModel()

    @ObservedObject var authViewModel = AuthViewModel.shared


    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State var alertTitle = ""
    
    enum AuthMode {
        case login, signUp, forgotPassword
    }
    
    @State private var authMode: AuthMode = .login
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Text(authMode == .signUp ? "Create Account" :
                         authMode == .forgotPassword ? "Forgot Password" : "Welcome")
                        .font(.custom(FontHelper.bold.rawValue, size: 24))
                        .foregroundColor(.black)

                    Text(authMode == .signUp ? "Sign up to get started" :
                         authMode == .forgotPassword ? "Enter your email to reset password" :
                         "Please select method to login")
                        .font(.custom(FontHelper.regular.rawValue, size: 14))
                        .foregroundColor(.gray)

                    if authMode != .forgotPassword {
                        HStack(spacing: 10) {
                            SignInButton(text: "Google Sign in", logo: ImageResource.google) {
                                GoogleLoginManager.shared.signIn()
                            }
                            SignInButton(text: "Apple Sign in", logo: ImageResource.appleLogo) {
                                GoogleLoginManager.shared.signInWithApple()
                            }
                        }
                        .padding(.top, 20)
                        
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.5))

                            Text("OR")
                                .font(.custom(FontHelper.regular.rawValue, size: 14))
                                .foregroundColor(.gray)

                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(.horizontal, 30)
                    }

                    VStack(spacing: 15) {
                        CustomTextField(icon: "envelope", placeholder: "Enter your email", text: $email)
                        
                        if authMode != .forgotPassword {
                            CustomTextField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                        }
                    }
                    .padding(.horizontal, 20)

                    if authMode == .login {
                        HStack {
                            Spacer()
                            Button(action: {
                                authMode = .forgotPassword
                            }) {
                                Text("Forget Password")
                                    .font(.custom(FontHelper.regular.rawValue, size: 14))
                                    .foregroundColor(ColorHelper.primary.color)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    Button(action: handleAuthAction) {
                        Text(authMode == .signUp ? "Sign Up" :
                             authMode == .forgotPassword ? "Send Reset Link" : "Login")
                            .font(.custom(FontHelper.bold.rawValue, size: 18))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorHelper.primary.color)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)

                    if authMode != .forgotPassword {
                        HStack {
                            Text(authMode == .signUp ? "Already have an account?" : "Don't have an account?")
                                .font(.custom(FontHelper.regular.rawValue, size: 14))
                                .foregroundColor(.black)

                            Button(action: {
                                authMode = (authMode == .login) ? .signUp : .login
                            }) {
                                Text(authMode == .signUp ? "Login Now" : "Sign up now")
                                    .font(.custom(FontHelper.bold.rawValue, size: 14))
                                    .foregroundColor(ColorHelper.primary.color)
                            }
                        }
                    }

                    Spacer(minLength: 150)
                }
                .padding()
                .frame(minHeight: geometry.size.height)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }

        .onAppear {
            GoogleLoginManager.shared.isSignedIn = false
            scanCollectionViewModel.fetchScans()
        }
        .onChange(of:  showAlert) { newValue in
                    AlertManager.shared.showAlert(
                        title: alertTitle,
                        message: alertMessage,
                        primaryButtonTitle: "OK",
                        primaryAction: {
                            authMode = .login
                        },
                        showSecondaryButton: false  // Show the second button
                    )
                }
    }
    
    private func handleAuthAction() {
        // Email Validation
        guard isValidEmail(email) else {
            alertMessage = "Please enter a valid email address."
            alertTitle = "Invalid Email"
            showAlert = true
            return
        }

        // Password Validation (only for login and sign-up)
        if authMode != .forgotPassword {
            guard isValidPassword(password) else {
                alertMessage = "Password must be at least 6 characters long."
                alertTitle = "Weak Password"
                showAlert = true
                return
            }
        }

        switch authMode {
        case .login:
            authViewModel.signInWithEmail(email: email, password: password) { success in
                if success {
                    DDLogDebug("Successfully logged in")
                    GoogleLoginManager.shared.isSignedIn = true
                    GoogleLoginManager.shared.email = email
                    GoogleLoginManager.shared.userName = extractName(from: email)
                } else {
                    alertMessage = "Login failed. Please check your credentials."
                    alertTitle = "Login Failed"
                    showAlert = true
                }
            }
        case .signUp:
            authViewModel.signUpWithEmail(email: email, password: password) { success in
                if success {
                    DDLogDebug("Successfully Signed Up")
                    GoogleLoginManager.shared.isSignedIn = true
                    GoogleLoginManager.shared.email = email
                    GoogleLoginManager.shared.userName = extractName(from: email)
                } else {
                    alertMessage = "Sign-up failed. Please try again."
                    alertTitle = "Sign-up Failed"
                    showAlert = true
                }
            }
        case .forgotPassword:
            authViewModel.forgotPassword(email: email) { success in
                if success {
                    alertTitle = "Forgot Password"
                    alertMessage = "Successfully sent reset email. Please check your email."
                } else {
                    alertTitle = "Forgot Password"
                    alertMessage = "Failed to send reset email. Please try again."
                }
                showAlert = true
            }
        }
    }
    // Validate Email Format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }

    // Validate Password Strength
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 4
    }
    func extractName(from email: String) -> String {
        guard let namePart = email.split(separator: "@").first else {
            DDLogWarn("extractName: Invalid email format - \(email)")
            return ""
        }
        let cleaned = namePart
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        
        DDLogInfo("extractName: Extracted name - \(cleaned)")
        return cleaned
    }


}

#Preview {
    LoginScreen(navigationManager: NavigationManager(), postViewModel: PostViewModel(),commonViewModel: CommonViewModel())
}



struct SocialLoginButton: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon) // Use SF Symbols or replace with actual images
                .foregroundColor(.black)
            Text(title)
                .font(.custom(FontHelper.bold.rawValue, size: 16))
                .foregroundColor(.black)
        }
        .frame(width: 140, height: 50)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.custom(FontHelper.regular.rawValue, size: 16))
            } else {
                TextField(placeholder, text: $text)
                    .font(.custom(FontHelper.regular.rawValue, size: 16))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}


struct SignInButton: View {
    var text:String
    var logo:ImageResource
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Image(logo) // Replace with your Google icon asset
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(.leading,10)
                
                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black)
                
                
                Spacer()
            }
            .padding()
            .frame(height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray, lineWidth: 1)
            )
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.gray.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}


