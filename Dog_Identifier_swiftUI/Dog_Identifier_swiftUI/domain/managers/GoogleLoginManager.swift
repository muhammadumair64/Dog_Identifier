import Foundation
import FirebaseAuth
import GoogleSignIn
import UIKit
import Firebase
import AuthenticationServices
import CryptoKit
import CocoaLumberjack

class GoogleLoginManager: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userName: String?
    @Published var email: String?
    @Published var address: String?
    @Published var phone: String?
    @Published var lat: Double?
    @Published var long: Double?
    @Published var profilePic: URL?
    
    static let shared = GoogleLoginManager()
    
    private var currentNonce: String?  // Store the nonce for Apple Sign-In

    private override init() {}

    // MARK: - Google Sign-In
    func signIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Firebase clientID is missing.")
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Failed to retrieve rootViewController for Google Sign-In.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user, let idToken = user.idToken?.tokenString else {
                print("Google Sign-In result is missing user or ID token.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase sign-in failed: \(error.localizedDescription)")
                    return
                }
                self.populateUserData(user: user.profile)
            }
        }
    }

    // MARK: - Apple Sign-In
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    // MARK: - Email & Password Authentication

    /// Login with Email and Password
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.email = email
        self.userName = self.extractName(from: email)
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Email sign-in failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "SignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
                return
            }
            print("Email sign-in : \(user)")
            
            self.isSignedIn = true
//            self.email = user.email
//            self.userName = user.displayName

            completion(.success(true))
        }
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


    /// Sign Up with Email and Password
    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        self.email = email
        self.userName = self.extractName(from: email)
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Sign-up failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "SignUpError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not created"])))
                return
            }
            print("Email sign-up : \(user)")
            self.isSignedIn = true
//            self.email = user.email
//            self.userName = user.displayName
        
            completion(.success(true))
        }
    }

    /// Forgot Password
    func forgotPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Password reset failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            print("Password reset email sent successfully")
            completion(.success(()))
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.clearUserData()
                print("User successfully signed out.")
            }
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }
    // MARK: - Delete Account
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "User not found.")
            return
        }

        user.delete { error in
            if let error = error {
                if let errorCode = (error as NSError?)?.code, errorCode == AuthErrorCode.requiresRecentLogin.rawValue {
                    completion(false, "Please re-authenticate before deleting your account.")
                } else {
                    completion(false, "Account deletion failed: \(error.localizedDescription)")
                }
                return
            }

            // Sign out after successful deletion
            DispatchQueue.main.async {
                self.isSignedIn = false
                self.clearUserData()
            }

            print("User account successfully deleted.")
            completion(true, nil)
        }
    }

    

    // MARK: - User Data Helpers
    private func populateUserData(user: GIDProfileData?) {
        DispatchQueue.main.async {
            self.isSignedIn = true
            self.userName = user?.name
            self.email = user?.email
            self.profilePic = user?.imageURL(withDimension: 200)
            self.address = ""
            self.phone = ""
            self.lat = 0.0
            self.long = 0.0
        }
    }

    private func clearUserData() {
        self.userName = nil
        self.email = nil
        self.address = nil
        self.phone = nil
        self.lat = nil
        self.long = nil
        self.profilePic = nil
    }
}

// MARK: - Apple Sign-In Delegate
extension GoogleLoginManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("Apple Sign-In failed: No Apple ID credential found")
            return
        }

        guard let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            print("Apple Sign-In failed: Identity token is missing.")
            return
        }

        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: identityToken,
            rawNonce: currentNonce
        )

        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                print("Firebase Apple Sign-In failed: \(error.localizedDescription)")
                return
            }
            // Apple returns email and fullName only on first sign-in
                   let firstName = appleIDCredential.fullName?.givenName
                   let lastName = appleIDCredential.fullName?.familyName
                   let email = appleIDCredential.email

            DispatchQueue.main.async {
                        self.isSignedIn = true

//                        // Handle name (first + last if available)
//                        if let firstName = firstName, let lastName = lastName {
//                            self.userName = "\(firstName) \(lastName)"
//                            DDLogInfo("Apple user name: \(self.userName ?? "")")
//                        } else {
//                            self.userName = Auth.auth().currentUser?.displayName
//                            DDLogDebug("Apple user name fallback: \(self.userName ?? "nil")")
//                        }
          
                        // Handle email (only first login returns email)
                        if let email = email {
                            self.email = email
                            DDLogInfo("Apple user email: \(email)")
                            self.userName = self.extractName(from: email)
                        } else {
                            self.email = Auth.auth().currentUser?.email
                            DDLogDebug("Apple user email fallback: \(self.email ?? "nil")")
                            self.userName = self.extractName(from:  self.email ?? "")
                        }
                    }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple Sign-In failed: \(error.localizedDescription)")
    }
}

// MARK: - Nonce Utility Functions
private func randomNonceString(length: Int = 32) -> String {
    let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        if status != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed.")
        }
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    return hashedData.map { String(format: "%02x", $0) }.joined()
}
