import SwiftUI
import FirebaseAuth
import CocoaLumberjack

struct ProfileScreen: View {
    
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject private var googleLoginManager = GoogleLoginManager.shared
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var commonViewModel: CommonViewModel
    
    @State  var showErrorDialog: Bool = false // State for showing error dialog
    @State private var errorMessage: String = ""     // Error message for the dialog
    @State private var showLogin: Bool = false

    var body: some View {
        VStack {

            if(showLogin){
                Color.clear.onAppear{showErrorDialog = false}
                LoginScreen(navigationManager: navigationManager,postViewModel: postViewModel,commonViewModel: commonViewModel)
                    .onAppear{
                        showLogin = false
                    }
            }
            if let currentUser = userViewModel.currentUser {
                ProfileCollectionView(navigationManager: navigationManager,
                                      userViewModel: userViewModel,
                                      postViewModel: postViewModel,
                                      profile: currentUser)
                    .onAppear {
                        fetchProfileData(for: currentUser)
                        postViewModel.fetchUserPosts()
                    }
            } else if googleLoginManager.isSignedIn {
                Color.clear.onAppear {
                    DDLogDebug("Signed in from Google state changed")
                    handleGoogleSignedInState()
                }
            } else {
                LoginScreen(navigationManager: navigationManager,postViewModel: postViewModel,commonViewModel: commonViewModel)
            }
        }
        .onChange(of: showErrorDialog) { newValue in
            if(newValue){
                AlertManager.shared.showAlert(
                                 title: "Something Went Wrong!",
                                 message: "Unable to Create Profile, Please Check Network Connection or Try another Email",
                                 primaryButtonTitle: "OK",
                                 primaryAction: {
                                     showErrorDialog =  false
                                     print("Yes tapped \(showErrorDialog) ")
                                     showLogin = true
                                 },
                                 showSecondaryButton: false
                             )
            }
        }

        .padding()
    }
}

extension ProfileScreen {
    private func fetchProfileData(for user: UserResponse) {
        userViewModel.getFollowers(userId: String(user.userId))
        userViewModel.getFollowing(userId: String(user.userId))
        postViewModel.refreshUserPosts(userId: Int(user.userId))
    }
    
    private func handleGoogleSignedInState() {
        DDLogDebug("Inside the handle state")
        guard let authUser = Auth.auth().currentUser else {
            DDLogError("Auth user is nil while signed in with Google.")
            return
        }
        
        userViewModel.getUserByUid(uid: authUser.uid) {
            // Once the user data is fetched or error message is set
            if !userViewModel.errorMessage.isEmpty {
                DDLogDebug("Error message found, navigating to profile creation")
               // navigationManager.push(.createProfile)
                createUser()
                
            } else if let user = userViewModel.currentUser {
                DDLogDebug("User found, fetching profile data")
                fetchProfileData(for: user)
            }
        }
    }
    
    func createUser() {
        if let currentUser = Auth.auth().currentUser {
            DDLogDebug("Current User UID Before Create : \(currentUser.uid)")
            DDLogDebug("name= \(googleLoginManager.userName ?? "")")
            var user = myUser()
            user.uid = "\(currentUser.uid)"
            user.userId = 0
            user.name =  googleLoginManager.userName ?? ""
            user.email = googleLoginManager.email ?? ""
            user.address = ""
            user.bio = ""
            user.imageUrl = googleLoginManager.profilePic?.absoluteString
            user.notificationToken = "dummyFCMToken"
            user.lat =  0.0
            user.lng =  0.0
            user.number = ""
        
            
            DDLogVerbose("Created user: \(user)")
            
            userViewModel.createUser(user: user) { result in
                switch result {
                case .success(let createdUser):
                    DDLogInfo("Successfully created user: \(createdUser)")
                    showLogin =  false
                    handleGoogleSignedInState()
                    //navigationManager.pop() // Navigate to the desired screen
                case .failure(let error):
                    DDLogError("Failed to create user: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    showErrorDialog = true // Trigger the error dialog
                }
            }
        } else {
            DDLogError("No user is currently signed in.")
        }
    }
}

#Preview {
    ProfileScreen(
        navigationManager: NavigationManager(),
        userViewModel: UserViewModel(),
        postViewModel: PostViewModel(),
        commonViewModel: CommonViewModel()
    )
}
