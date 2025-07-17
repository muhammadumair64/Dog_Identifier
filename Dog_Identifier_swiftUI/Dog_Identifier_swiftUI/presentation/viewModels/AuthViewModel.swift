


import FirebaseAuth
import Combine

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    
    static let shared = AuthViewModel()
    
    private init() {}

    /// Login with Email and Password
    func signInWithEmail(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Email sign-in failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            self.isSignedIn = true
            completion(true)
        }
    }

    /// Sign Up with Email and Password
    func signUpWithEmail(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Sign-up failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            self.isSignedIn = true
            completion(true)
        }
    }

    /// Forgot Password
    func forgotPassword(email: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("Password reset failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }
}
