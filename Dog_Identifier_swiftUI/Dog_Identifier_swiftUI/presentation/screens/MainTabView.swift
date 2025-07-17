//
//  MainTabView.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 18/04/2025.
//

import Foundation
import SwiftUI
import CocoaLumberjack
import Lottie

struct MainTabView: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var commonViewModel: CommonViewModel
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var cameraViewModel: CameraViewModel

    @State var presentSideMenu = false
    @State private var showMailCompose = false
    @State private var showAlert = false
    @State private var hasViewAppeared = false
    @State private var selectedImage: UIImage? = nil
    @State private var isDialogPresented: Bool = false
    
    @State private var isShowLimitDialog :Bool = false
    var isPro = UserDefaultManager.shared.get(forKey: .isPremiumUser) ??  false
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom){
                Spacer()
                VStack {
                    HeaderView(
                        navigationManager: navigationManager,
                        presentSideMenu: $presentSideMenu,
                        selectedTab: $commonViewModel.selectedTab,
                        userViewModel: userViewModel,
                        commonViewModel: commonViewModel
                    )
                    .padding(.top, 5)
                    .zIndex(1)
                    
                    VStack {
                        switch commonViewModel.selectedTab {
                        case .home:
                            HomeScreen(
                                navigationManager: navigationManager,
                                postViewModel: postViewModel,
                                commonViewModel: commonViewModel,
                                cameraViewModel: cameraViewModel)
                        case .feeds:
                            FeedScreen(
                                navigationManager: navigationManager,
                                postViewModel: postViewModel,commonViewModel: commonViewModel)
                        case .identify:
                            IdentifyScreen(
                                navigationManager: navigationManager,
                                commonViewModel: commonViewModel,
                                cameraViewModel: cameraViewModel)
                        case .profile:
                            ProfileScreen(
                                navigationManager: navigationManager,
                                userViewModel: userViewModel,
                                postViewModel: postViewModel,
                                commonViewModel: commonViewModel)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
              .opacity(presentSideMenu ? 0.7 : 1)
                
                if(commonViewModel.showBottom){
                    ZStack {
                        Circle()
                            .fill(ColorHelper.primary.color)
                            .frame(width: 70, height: 70)
                        Image(ImageResource.scanIc)
                            .resizable()
                            .frame(width: 30, height: 30)
                            .tint(ColorHelper.primary.color)
                    }
                    .padding(.bottom, 55)
                    .onTapGesture {
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            isDialogPresented = true
                        } else {
                            print("Clicked SCAN")
//                            navigationManager.push(.cameraScreen)
                            if(!commonViewModel.isShowingDialog){
                               isShowLimitDialog = true
                            }
                        }
            
                    }
                    .opacity(presentSideMenu ? 0.7 : 1)
                    .zIndex(10)

                    // Custom Bottom Navigation Bar
                    HStack {
                        Spacer()
                        NavBarItem(
                            icon: commonViewModel.selectedTab == .home
                                ? ImageResource.homeSelected : ImageResource.homeIc,
                            title: "Home",
                            isSelected: commonViewModel.selectedTab == .home
                        ) {
                            commonViewModel.selectedTab = .home
                        }
                        Spacer()
                        NavBarItem(
                            icon: commonViewModel.selectedTab == .feeds
                                ? ImageResource.feedSelected : ImageResource.feedIc,
                            title: "Feeds",
                            isSelected: commonViewModel.selectedTab == .feeds
                        ) {
                            commonViewModel.selectedTab = .feeds
                        }
                        Spacer()
                        VStack {}  // Empty View
                        Spacer()
                        NavBarItem(
                            icon: commonViewModel.selectedTab == .identify
                                ? ImageResource.searchSelected
                                : ImageResource.searchIc,
                            title: "Identify",
                            isSelected: commonViewModel.selectedTab == .identify
                        ) {
                            commonViewModel.selectedTab = .identify
                        }
                        Spacer()
                        NavBarItem(
                            icon: commonViewModel.selectedTab == .profile
                                ? ImageResource.userSelected : ImageResource.userIc,
                            title: "Profile",
                            isSelected: commonViewModel.selectedTab == .profile
                        ) {
                            commonViewModel.selectedTab = .profile
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .background(
                        Image(ImageResource.navBottomBg)
                            .resizable()
                            .padding(.horizontal, -30)
                            .padding(.bottom, -25)
                    )
                    .opacity(presentSideMenu ? 0.7 : 1)
                    
                    ZStack {
                        // Background dimmed layer with tap to dismiss
                        if presentSideMenu {
                            Color.black.opacity(0.3)
                                .edgesIgnoringSafeArea(.all)
                                .onTapGesture {
                                    withAnimation {
                                        DDLogInfo("Tapped outside to dismiss side menu")
                                        presentSideMenu = false
                                    }
                                }
                                .transition(.opacity)
                                .zIndex(80)
                            
                            GeometryReader { geometry in
                                SideMenuView(
                                    navigationManager: navigationManager,
                                    commonViewModel: commonViewModel ,
                                    userViewModel: userViewModel,
                                    selectedSideMenuTab: $commonViewModel.selectedSideMenuTab,
                                    presentSideMenu: $presentSideMenu,
                                    showMailCompose: $showMailCompose,
                                    showAlert: $showAlert
                                )
                                .frame(width: geometry.size.width * 0.75)
                                .offset(x: presentSideMenu ? 0 : -geometry.size.width)
                                .animation(.easeInOut(duration: 0.3), value: presentSideMenu)
                           
                            }.zIndex(100)
                        }
                    }
                    .onChange(of: presentSideMenu) { isShown in
                        if isShown {
                            DDLogDebug("Side menu opened — refresh userId")
                
                            guard let userId: Int = UserDefaultManager.shared.get(forKey: UserDefaultManager.Key.currentUser) else {
                                DDLogError("User ID is not available.")
                                commonViewModel.isUserLogin = false
                                return
                            }
                            if(userId != 0){
                                commonViewModel.isUserLogin = true
                            }else{
                                commonViewModel.isUserLogin = false
                            }
                        
    
                        }
                    }
                    .zIndex(90)
                }else{
                    VStack{
                        
                    }.frame(height: 1)
                }
                
                // Scan Button



            }
            
        }
        .onChange(of: selectedImage) { value in
            cameraViewModel.capturedImage = value
            navigationManager.push(.scanningScreen)
        }
        .edgesIgnoringSafeArea(.bottom)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.width < -50 {
                        withAnimation {
                            presentSideMenu = false  // Close menu on swipe
                        }
                    }
                }
        )
        .animation(.easeInOut, value: presentSideMenu)
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                recipients: ["iobits.technologies1@gmail.com"],
                subject: "Customer Support Inquiry"
            )
        }
        .overlay{
            // Show the dialog overlay
            DialogPicker(selectedImage: $selectedImage, isPresented: $isDialogPresented)
            
            if(isPro && isShowLimitDialog ){
                Color.clear.onAppear{
                    navigationManager.push(.cameraScreen)
                    isShowLimitDialog =  false
                }
            }else{
                LimitDialog(navigationManager:navigationManager , isPresented: $isShowLimitDialog) {
                    navigationManager.push(.cameraScreen)
                }.zIndex(500)
            }
       
        }
        .onAppear{
            commonViewModel.showBottom =  true
            UserDefaultManager.shared.set(
                true, forKey: UserDefaultManager.Key.secondLaunch)
        }
    }
    
}

struct NavBarItem: View {
    let icon: ImageResource
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        VStack {
            Image(icon)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(
                    isSelected ? ColorHelper.primary.color : Color.gray
                )
                .tint(ColorHelper.primary.color)  // Apply the tint

            Text(title)
                .font(.caption)
                .foregroundColor(
                    isSelected ? ColorHelper.primary.color : Color.gray)
        }
        .padding(.vertical, 8)
        .padding(.top,20)
        .onTapGesture {
            action()
        }
    }
}


struct HeaderView: View {
    @ObservedObject var navigationManager: NavigationManager
    @Binding var presentSideMenu: Bool
    @Binding var selectedTab: Tab
    @ObservedObject private var googleLoginManager = GoogleLoginManager.shared
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var commonViewModel: CommonViewModel
    // Dynamically determine the title based on the selected tab
    private var headerTitle: String {
        switch selectedTab {
        case .home:
            return "Scan & Identify"
        case .feeds:
            return "Feeds"
        case .identify:
            return "Scan & Identify"
        case .profile:
            return "Profile"
        }
    }
    var isPro = UserDefaultManager.shared.get(forKey: .isPremiumUser) ??  false
    
    var body: some View {
        VStack {
            HStack {
                // Side Menu Icon
                Image(ImageResource.menuIcon)
                    .resizable()
                    .frame(width: 30, height: 30)
                    .onTapGesture {
                        withAnimation {
                            commonViewModel.showBottom =  true
                            presentSideMenu.toggle()
                        }
                    }

                // Header Title
                Text(headerTitle)
                    .font(Font.custom(FontHelper.bold.rawValue, size: 20))
                    .padding(.leading, 20)

                Spacer()  // Push content to the left
                if(!isPro){
                    LottieView(animation: .named(LottieHelper.premium.rawValue))
                                    .playing()
                                    .looping()
                                    .frame(maxWidth: 60)
                                    .frame(height: 60)
                                    .onTapGesture {
                                        navigationManager.push(.premiumScreen)
                                        AdsCounter.showProCounter = 0
                                    }
                }

                       
                
                if selectedTab == .profile && userViewModel.currentUser != nil {
                    Menu {
                        Button("Logout") {
                            googleLoginManager.signOut()
                            userViewModel.logoutUser()
                        }
                        Button("Delete Profile") {
                            googleLoginManager.signOut()
                            userViewModel.logoutUser()
//                            googleLoginManager.deleteAccount { success, message in
//                                if success {
//                                    userViewModel.logoutUser()
//                                    print("User successfully deleted and logged out.")
//                                }else{
//                                    googleLoginManager.signOut()
//                                    userViewModel.logoutUser()
//                                }
//                            }
                        }
                    } label: {
                        Image(ImageResource.menu)
                            .resizable()
                            .frame(width: 30, height: 30)
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background(Color.white)
    }
}

#Preview {
    MainTabView(
        navigationManager: NavigationManager(),postViewModel: PostViewModel(),commonViewModel: CommonViewModel(),userViewModel: UserViewModel(),cameraViewModel: CameraViewModel())
}
