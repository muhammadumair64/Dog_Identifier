
import SwiftUI
import FirebaseMessaging
import FirebaseAuth
import CocoaLumberjack

struct CreateProfileView: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject private var googleLoginManager = GoogleLoginManager.shared
    @ObservedObject private var locationManager = LocationManager()
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var location: String = ""
    let dummyFCMToken = "dummy_fcm_token_1234567890"
    
    @State private var isDialogPresented: Bool = false
    @State private var showLocationPermissionError: Bool = false
    @State private var showErrorDialog: Bool = false // State for showing error dialog
    @State private var errorMessage: String = ""     // Error message for the dialog
    
    @State private var fcmToken: String? = nil
    @StateObject var userViewModel = UserViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Profile Image
                ZStack {
                    if let profilePicURL = googleLoginManager.profilePic,
                       let imageData = try? Data(contentsOf: profilePicURL),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(radius: 5)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(radius: 5)
                    }
                }
                
                // Text Fields
                VStack(spacing: 16) {
                    TextFieldView(title: "Enter Name", hint: "Full Name", text: $fullName)
                    TextFieldView(title: "Email", hint: "Email address", text: $email)
                    TextFieldView(title: "Phone", hint: "Phone Number", text: $phoneNumber, showOptional: true)
                    
                    // Location Field
                    ZStack(alignment: .trailing) {
                        TextFieldView(title: "Location", hint: "Location", paddingRight: 130, text: $location,showOptional: true)
                        
                        Text("Get Automatically")
                            .font(Font.custom(FontHelper.medium.rawValue, size: 14))
                            .foregroundColor(Color.blue)
                            .padding(.trailing, 10)
                            .padding(.top, 30)
                            .onTapGesture {
                                DDLogVerbose("Fetching location...")
                                locationManager.fetchLocation()
                            }
                    }
                    .onChange(of: locationManager.currentAddress) { newLocation in
                        if let newLocation = newLocation {
                            location = newLocation
                        }
                    }
                }
                .padding(.horizontal)
                
                // Continue Button
                Button(action: {
                    createUser()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 40)
                
                if userViewModel.isUserCreated {
                    Color.clear.onAppear {
                        DDLogInfo("User Created Successfully")
                    }
                } else {
                    Color.clear.onAppear {
                        DDLogInfo("User Not Created")
                    }
                }
            }
            .padding(.top, 50)
        }
        .clipped()
        .onChange(of: locationManager.error) { error in
            if let error = error {
                DDLogInfo("Error updated: \(error)")
                if error == "Location Permission Denied" {
                    showLocationPermissionError = true
                }
            }
        }
        .alert(isPresented: $showLocationPermissionError) {
            Alert(
                title: Text("Location Permission Denied"),
                message: Text("Please enable location access in Settings."),
                primaryButton: .default(Text("Go to Settings")) {
                    locationManager.openAppSettings()
                },
                secondaryButton: .cancel()
            )
        }
        .onChange(of: showErrorDialog) { newValue in
            AlertManager.shared.showAlert(
                             title: "Something Went Wrong!",
                             message: "Unable to Upload Profile, Please Check Your Data or Network Connection",
                             primaryButtonTitle: "OK",
                             primaryAction: {
                                 print("Yes tapped")
                                 showErrorDialog =  false
                             },
                             showSecondaryButton: false
                         )

        }
        .onAppear {
            fullName = googleLoginManager.userName ?? ""
            email = googleLoginManager.email ?? ""
            locationManager.checkAuthorization()
            fetchFcmToken()
        }
    }
    
  
    
    func fetchFcmToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                DDLogError("Error fetching FCM token: \(error.localizedDescription)")
                return
            }
            
            if let token = token {
                DispatchQueue.main.async {
                    self.fcmToken = token
                }
            }
        }
    }
    
    func createUser() {
        if let currentUser = Auth.auth().currentUser {
            DDLogDebug("Current User UID: \(currentUser.uid)")
            
            var user = myUser()
            user.uid = "\(currentUser.uid)"
            user.userId = 0
            user.name = fullName
            user.email = email
            user.address = location
            user.bio = ""
            user.imageUrl = googleLoginManager.profilePic?.absoluteString
            user.notificationToken = dummyFCMToken
            user.lat = locationManager.latitude ?? 0.0
            user.lng = locationManager.longitude ?? 0.0
            user.number = phoneNumber
        
            
            DDLogVerbose("Created user: \(user)")
            
            userViewModel.createUser(user: user) { result in
                switch result {
                case .success(let createdUser):
                    DDLogInfo("Successfully created user: \(createdUser)")
                    navigationManager.pop() // Navigate to the desired screen
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


struct CreateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProfileView(navigationManager: NavigationManager())
    }
}

struct TextFieldView: View {
    var title: String
    var hint: String
    var paddingRight :CGFloat = 0
    @Binding var text: String
    var showOptional: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack{
                Text(title)
                    .font(Font.custom(FontHelper.extrabold.rawValue, size: 17))
                    .fontWeight(.bold)
                if(showOptional){
                    Text("Optional")
                        .font(Font.custom(FontHelper.medium.rawValue, size: 14))
                        .foregroundColor(ColorHelper.primary.color)
                }
    
            }
        
            
            TextField(hint, text: $text)
                .padding(.trailing , paddingRight)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ColorHelper.grayBG.color, lineWidth: 2))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 5)
    }
}
