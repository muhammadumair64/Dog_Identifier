import SwiftUI
import MessageUI
import CocoaLumberjack
import Lottie

enum SideMenuRowType: Int, CaseIterable {
    case support
//    case share
    case rateus
    case privacy
    case terms
    
    var title: String {
        switch self {
        case .support:
            return "VIP Support"
//        case .share:
//            return "Share"
        case .rateus:
            return "Rate Us"
        case .privacy:
            return "Privacy Policy"
        case .terms:
            return "Login"
            
        }
    }
    
    var titleAfterLogin: String {
        switch self {
        case .support:
            return "VIP Support"
//        case .share:
//            return "Share"
        case .rateus:
            return "Rate Us"
        case .privacy:
            return "Privacy Policy"
        case .terms:
            return "Log out"
            
        }
    }
    var iconName: String {
        switch self {
        case .support:
            return "support"
//        case .share:
//            return "share"
        case .rateus:
            return "rateus"
        case .privacy:
            return "privacy"
        case .terms:
            return "user_selected"
            
        }
    }
}
    
    struct SideMenuView: View {
        @ObservedObject var navigationManager: NavigationManager
        @ObservedObject var commonViewModel: CommonViewModel
        @ObservedObject var userViewModel: UserViewModel
        @Binding var selectedSideMenuTab: Int
        @Binding var presentSideMenu: Bool
        
        @Binding  var showMailCompose : Bool
        @Binding  var showAlert : Bool
        @State var userId = 0
        var body: some View {
            HStack {
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 270)
                        .shadow(color: .purple.opacity(0.1), radius: 5, x: 0, y: 3)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        ProfileImageView()
                            .padding(.bottom, 30)
//                        HStack {
//
//                            LottieView(animation: .named(LottieHelper.premium.rawValue))
//                                            .playing()
//                                            .looping()
//                                            .frame(maxWidth: 50)
//                                            .frame(height: 50)
//                            
//
//                            Text("Go Premium")
//                                .font(.system(size: 14, weight: .regular))
//                                .foregroundColor(.black)
//                                .bold()
//                        }
//                        .frame(height: 40)
//                        .onTapGesture {
//                            //navigationManager.push(.premiumScreen)
//                            presentSideMenu = false
//                        }
                        
                        ForEach(SideMenuRowType.allCases, id: \.self) { row in
                            let title = (commonViewModel.isUserLogin) ? row.titleAfterLogin : row.title
                            RowView(
                                isSelected: selectedSideMenuTab == row.rawValue,
                                imageName: row.iconName,
                                title: title
                            ) {
                                handleSideMenuSelection(for: row)
                            }
                        }

                        
                        Spacer()
                    }
                    .padding(.top, 100)
                    .frame(width: 270)
                }
                
                Spacer()
            }

            .background(Color.clear)
        }
        
        private func handleSideMenuSelection(for row: SideMenuRowType) {
            let viewModel = AppSideMenuViewModel()
            switch row {
            case .support:
                print("Support Selected")
                AdsCounter.isShowOpenAd =  false
                if MFMailComposeViewController.canSendMail() {
                    showMailCompose = true
                } else {
                    showAlert = true
                }
                
//            case .share:
//                print("Share Selected")
//                // Add functionality for Share
//                shareApp()
                
                
            case .rateus:
                print("Rate Us Selected")
                showRateUs()
                // Add functionality for Rate Us
                
            case .privacy:
                viewModel.showPolicy()
                
            case .terms:
                commonViewModel.selectedTab = .profile
            }
            
            selectedSideMenuTab = row.rawValue
            presentSideMenu.toggle()
        }
        
        func ProfileImageView() -> some View {
            VStack(alignment: .center) {
                Text("Butterfly Identifier")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ColorHelper.primary.color)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        
        func RowView(isSelected: Bool, imageName: String, title: String, action: @escaping (() -> Void)) -> some View {
            Button {
                action()
            } label: {
                VStack(alignment: .leading) {
                    HStack(spacing: 15) {
                        Image(imageName)
                            .resizable()
                            .frame(width: 20, height: 23)
                        
                        Text(title)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.black)
                            .bold()
                        
                        Spacer()
                    }
                }
                .padding(.leading, 20)
            }
            .frame(height: 50)
        }
        
        func shareApp() {
            AdsCounter.isShowOpenAd =  false
            //            @StateObject  var viewModel = AppSideMenuViewModel()
            //            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            //                DDLogError("Failed to get the root view controller.")
            //                return
            //            }
            //
            //            viewModel.shareApp(from: rootVC)
            
        
        }
        
        
        
        
        func showRateUs(){
            AdsCounter.isShowOpenAd =  false
            @StateObject  var viewModel = AppSideMenuViewModel()
            guard (UIApplication.shared.keyWindow?.rootViewController) != nil else {
                DDLogError("Failed to get the root view controller.")
                return
            }
            viewModel.promptForRating()
        }
    }
