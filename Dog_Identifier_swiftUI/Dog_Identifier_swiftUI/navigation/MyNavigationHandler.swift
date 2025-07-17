import SwiftUI
import CocoaLumberjack

class NavigationManager: ObservableObject {
    @Published var navigationStack: [AppDestination] = []

       var currentDestination: AppDestination? {
           navigationStack.last
       }

       func push(_ destination: AppDestination) {
           navigationStack.append(destination)
       }

       func pop() {
           _ = navigationStack.popLast()
       }
}

enum AppDestination: Hashable {
    case mainTabView
    case onboardingScreen
    case cameraScreen
    case scanningScreen
    case scanResultsScreen
    case knowAboutScreen
    case dogDetailScreen
    case blogDetailScreen
    case postDetails
    case profile
    case createProfile
    case userPostDetailScreen
    case collectionDetailsScreen
    case createPost
    case premiumScreen
  }

struct NavigationHandler: View {
    @ObservedObject var navigationManager: NavigationManager
    @StateObject var cameraViewModel = CameraViewModel()
    @StateObject var commonViewModel = CommonViewModel()
    @StateObject var postViewModel = PostViewModel()
    @StateObject var userViewModel = UserViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Switch on the current destination to determine what view to show
                if let destination = navigationManager.currentDestination {
                    switch destination {
                    case .mainTabView:
                        MainTabView(navigationManager: navigationManager,postViewModel: postViewModel,commonViewModel: commonViewModel,userViewModel: userViewModel ,cameraViewModel: cameraViewModel)
                            .navigationBarBackButtonHidden(true)
                    case .onboardingScreen:
                        OnboardingScreen(navigationManager: navigationManager)
                            .navigationBarBackButtonHidden(true)
                    case .cameraScreen:
                        CameraScreen(navigationManager: navigationManager, cameraViewModel: cameraViewModel)
                    case .scanningScreen:
                        ScanningScreen(navigationManager: navigationManager, cameraViewModel: cameraViewModel)
                    case .scanResultsScreen:
                        ScanningResultScreen(navigationManager: navigationManager, cameraViewModel: cameraViewModel,commonViewModel:commonViewModel,postViewModel: postViewModel)
                    case .knowAboutScreen:
                        KnowAboutScreen(navigationManager: navigationManager,commonViewModel: commonViewModel ,cameraViewModel: cameraViewModel)
                    case .dogDetailScreen:
                        DogDetailsView(navigationManager: navigationManager, commonViewModel: commonViewModel)
                    case .blogDetailScreen:
                        BlogsDetailScreen(navigationManager: navigationManager, commonViewModel: commonViewModel)
                    case .postDetails:
                     PostDetailView(navigationManager: navigationManager , postViewModel: postViewModel,userViewModel:userViewModel,commonViewModel:commonViewModel)
                    case .profile:
                        ProfileScreen(navigationManager: navigationManager,userViewModel: userViewModel,postViewModel: postViewModel,commonViewModel:commonViewModel)
                    case .createProfile:
                        CreateProfileView(navigationManager: navigationManager)
                    case .createPost:
                        CreatePostView(navigationManager: navigationManager,postViewModel: postViewModel, commonViewModel: commonViewModel)
                    case .userPostDetailScreen:
                        UserPostDetailScreen(navigationManager: navigationManager , postViewModel: postViewModel)
                    case .collectionDetailsScreen:
                        CollectionDetailsScreen(navigationManager: navigationManager , postViewModel: postViewModel)
                    case .premiumScreen:
                        PremiumPlanView(navigationManager: navigationManager, commonViewModel: commonViewModel)
                    }
        
                } else {
                    SplashScreen(navigationManager: navigationManager)
                }
            }.onAppear{
                InternetManager.shared.isInternetAvailable { isAvailable in
                    if isAvailable {
                        DDLogDebug("Internt Is Available")
                        postViewModel.refreshPosts()
                    } else{
                        DDLogError("NO INTERNET Available")
                    }
                }
                DDLogDebug("Before Fetching Dogs")
                commonViewModel.fetchDogs()
                    let userId = UserDefaultManager.shared.get(forKey: .currentUser) ?? 0
                    if userId != 0 {
                        userViewModel.fetchUser(userId: userId)
                        postViewModel.refreshUserPosts(userId: userId)
                    }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Avoid nested navigation views on iPads
        .overlay(CustomAlertView())
    }

}



