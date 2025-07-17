import SwiftUI
import CocoaLumberjack
import FirebaseAuth

struct CreatePostView: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var commonViewModel: CommonViewModel
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var butterflyType: String = ""
    @State private var description: String = ""
    @State private var selectedImage: UIImage?
    @State private var isDialogPresented: Bool = false
    @StateObject private var locationManager = LocationManager()
    @State private var userId = 0
    @State private var showLocationPermissionError: Bool = false

    @FocusState private var isDescriptionFocused: Bool
    
    @State var showErrorDialog = false
    
   // @StateObject private var adsManager = AdsManager.shared
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Navigation Bar
                    HStack {
                        Button(action: {
                            navigationManager.pop()
                        }) {
                            Image(ImageResource.backBtn)
                                .foregroundColor(.green)
                        }
                        Text("Create Post")
                            .font(Font.custom(FontHelper.bold.rawValue, size: 20))
                            .foregroundColor(.black)
                            .padding(.leading, 20)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
//                    NativeAdView(adType: .withoutMedia)
//                         .frame(height: 200)
//                        .background(ColorHelper.primary.color.opacity(0.1))
//                        .cornerRadius(20)
//                        .padding(.horizontal ,15)
                    
                    // Title Input
                    TextField("Title of the post", text: $title)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8).stroke(
                                .gray.opacity(0.5), lineWidth: 1
                            )
                        )
                        .padding(.horizontal)

                    // Location Input
                    ZStack(alignment: .trailing) {
                        TextField("Location", text: $location)
                            .font(Font.custom(FontHelper.regular.rawValue, size: 14))
                            .disabled(true)
                            .padding(.trailing, 130)

                        HStack {
                            if locationManager.isFetchingLocation {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 10)
                            }
                            Text("Get Automatically")
                                .font(Font.custom(FontHelper.medium.rawValue, size: 14))
                                .foregroundColor(ColorHelper.primary.color)
                                .padding(.trailing, 10)
                                .onTapGesture {
                                    locationManager.fetchLocation()
                                }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(
                            Color.gray.opacity(0.5), lineWidth: 1
                        )
                    )
                    .padding(.horizontal)
                    .onChange(of: locationManager.currentAddress) { newLocation in
                        if let newLocation = newLocation {
                            location = newLocation
                        }
                    }

                    // Butterfly Type Picker
//                    Menu {
//                        Button("Insect") { butterflyType = "Insect" }
//                        Button("Butterfly") { butterflyType = "Butterfly" }
//                    } label: {
//                        HStack {
//                            Text(butterflyType.isEmpty ? "Select Butterfly Type" : butterflyType)
//                                .foregroundColor(butterflyType.isEmpty ? .gray : .black)
//                                .font(Font.custom(FontHelper.regular.rawValue, size: 14))
//                            Spacer()
//                            Image(systemName: "chevron.down")
//                                .foregroundColor(.gray)
//                        }
//                        .padding()
//                        .background(
//                            RoundedRectangle(cornerRadius: 8).stroke(
//                                Color.gray.opacity(0.5), lineWidth: 1
//                            )
//                        )
//                    }
//                    .padding(.horizontal)
//                    .zIndex(10)

                    // Description Input
//                    TextField("Enter Description", text: $description)
//                        .font(Font.custom(FontHelper.regular.rawValue, size: 15))
//                        .padding()
//                        .frame(height: 130, alignment: .topLeading)
//                        .background(
//                            RoundedRectangle(cornerRadius: 8).stroke(
//                                .gray.opacity(0.5), lineWidth: 1
//                            )
//                        )
//                        .focused($isDescriptionFocused)
//                        .padding(.horizontal)
//                        .zIndex(100)
                    DescriptionView(description: $description)
                    // Image Upload Section
                    HStack {
                        VStack {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxHeight: 150)
                                    .cornerRadius(10)
                                    .clipped()
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color.gray)
                                    Text("Drop your image here, or browse")
                                        .font(Font.custom(FontHelper.regular.rawValue, size: 15))
                                        .foregroundColor(.gray)
                                    Text("Support PNG, JPEG, WebP")
                                        .font(Font.custom(FontHelper.regular.rawValue, size: 12))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8).stroke(
                                        Color.gray.opacity(0.5), lineWidth: 1
                                    )
                                )
                                .contentShape(Rectangle()) // Ensure entire area is tappable
                                .onTapGesture {
                                    isDialogPresented = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 150)
                    .zIndex(-1) // Prevent interference with the description field

                    // Post Button
                    Button(action: {
                        if validateFields() {
                            postViewModel.uploadImage(
                                image: selectedImage ?? UIImage(),
                                userId: userId,
                                uid: Auth.auth().currentUser?.uid ?? "",
                                title: title,
                                description: description,
                                location: location,
                                lat: Float(locationManager.latitude ?? 0.0),
                                lng: Float(locationManager.longitude ?? 0.0),
                                category: "dogs"
                            )
                        } else {
                            DDLogError("All fields are required!")
                            showErrorDialog = true
                        }
                    }) {
                        Text("Post")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorHelper.primary.color)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
        if postViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Ad Loading...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .shadow(radius: 5)
                }
            }
        }
        .overlay{
       //     adsManager.isLoading ? LoadingDialogView() : nil
            DialogPicker(
                selectedImage: $selectedImage, isPresented: $isDialogPresented)
        }
        .onChange(of: locationManager.error) { error in
            if let error = error {
                DDLogInfo("Error updated: \(error)")
                if error == "Location Permission Denied" {
                    showLocationPermissionError = true
                }
            }
        }
        .onChange(of: postViewModel.isPostUploaded) { isUploaded in
            if isUploaded {
                postViewModel.isPostUploaded =  false
                DDLogDebug("before poping out screen")
//                adsManager.interAdCallForScreen(){
//                  
//                  
//                }
                AlertManager.shared.showAlert(
                    title: "Post Uploaded Successfully",
                    message: "Your post has been successfully uploaded. Thank you for sharing! Tap OK to view your feed",
                    primaryButtonTitle: "Ok",
                    primaryAction: {
                        commonViewModel.selectedTab = .feeds
                        postViewModel.refreshPosts()
                        navigationManager.pop()
                    },
                    showSecondaryButton: false  // Show the second button
                )
            }
        }
        .onChange(of: showErrorDialog) { newValue in
            AlertManager.shared.showAlert(
                             title: "Something Went Wrong!",
                             message: "Unable to Upload Post, Please Check Your Data or Network Connection",
                             primaryButtonTitle: "OK",
                             primaryAction: {
                                 print("Yes tapped")
                             },
                             showSecondaryButton: false
                         )
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
        .onAppear {
            if(postViewModel.imageForPost != nil){
                selectedImage = postViewModel.imageForPost
                title = postViewModel.titleForPost ?? ""
                description = postViewModel.descriptionForPost ?? ""
            }
            
            
            guard let userId: Int = UserDefaultManager.shared.get(
                forKey: UserDefaultManager.Key.currentUser
            ) else {
                DDLogError("User ID is not available.")
                return
            }
            DDLogInfo("User ID is \(userId)")
            self.userId = userId
        }
    }

    struct DescriptionView: View {
        @Binding var description: String
        @FocusState private var isDescriptionFocused: Bool

        var body: some View {
            VStack {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.gray.opacity(0.5), lineWidth: 1)
                        .background(Color.white)
                        .frame(height: 130)

                    TextEditor(text: $description)
                        .font(Font.custom(FontHelper.regular.rawValue, size: 15))
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .frame(height: 130)
                        .background(Color.clear)
                        .focused($isDescriptionFocused)
                        .onChange(of: description) { newValue in
                            if newValue.contains("\n") { // Detect Return key press
                                description.removeLast() // Remove the newline
                                isDescriptionFocused = false // Hide the keyboard
                            }
                        }
                    
                    if description.isEmpty { // Placeholder effect
                        Text("Enter Description")
                            .font(Font.custom(FontHelper.regular.rawValue, size: 15))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)
                .zIndex(100)
            }
        }
    }



    
    private func validateFields() -> Bool {
        guard !title.isEmpty, !description.isEmpty, selectedImage != nil else {
            DDLogWarn("Please fill all fields!")
            return false
        }
        return true
    }
}

#Preview {
    CreatePostView(navigationManager: NavigationManager(), postViewModel: PostViewModel(),commonViewModel: CommonViewModel())
}
