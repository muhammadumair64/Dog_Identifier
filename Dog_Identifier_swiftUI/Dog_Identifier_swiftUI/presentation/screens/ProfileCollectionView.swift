import SwiftUI
import CocoaLumberjack

struct ProfileCollectionView: View {
    
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var userViewModel: UserViewModel
    @ObservedObject var postViewModel: PostViewModel

    @StateObject var scanCollectionViewModel = ScanCollectionViewModel()
    
    var profile: UserResponse
    
    // Bottom overlay height
    private let overlayHeight: CGFloat = 130 // Adjust to match your actual overlay height
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Profile Header
            ScrollView(showsIndicators: false){
                VStack(spacing: 20) {
                    profileHeader
                    
                    // MARK: - Statistics Section
                    statisticsSection
                    
                    // MARK: - Tab Bar
                    tabBar
                    
                    // MARK: - Content Based on Tab Selection
                    if userViewModel.selectedTab == 0 {
                        // Collection Tab
                        if scanCollectionViewModel.scans.isEmpty {
                            emptyPlaceholder(message: "No collections available.")
                        } else {
                            collectionView
                        }
                    } else {
                        // Posts Tab
                        if postViewModel.userPosts.isEmpty {
                            emptyPlaceholder(message: "No posts available.")
                        } else {
                            postsView
                        }
                    }
                }
                .padding(.bottom, overlayHeight)
            }
            .background(Color.white.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            UserDefaultManager.shared.set(userViewModel.currentUser?.userId, forKey: UserDefaultManager.Key.currentUser)
            scanCollectionViewModel.fetchScans()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 8) {
            ZStack {
                if(profile.imageUrl.isEmpty){
                    MyRemoteImage(urlString: "https://www.rattanhospital.in/wp-content/uploads/2020/03/user-dummy-pic.png")
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                }else{
                    MyRemoteImage(urlString: profile.imageUrl)
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                }
        
            }
            Text(profile.name)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.black)
            Text(profile.address)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        HStack {
            VStack {
                Text(String(postViewModel.userPosts.count))
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Posts")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            VStack {
                Text(String(postViewModel.totalLikes))
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Likes")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            VStack {
                Text("\(userViewModel.followers.count)")
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Followers")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()

            VStack {
                Text("\(userViewModel.following.count)")
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Following")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    if userViewModel.selectedTab != index {
                        DDLogDebug("Tab switched to index: \(index)")
                        userViewModel.selectedTab = index
                    }
                }) {
                    Text(index == 0 ? "My Collections" : "My Posts")
                        .font(Font.custom(FontHelper.regular.rawValue, size: 16))
                        .foregroundColor(userViewModel.selectedTab == index ? .white : .black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(userViewModel.selectedTab == index ? ColorHelper.primary.color : Color.clear)
                        .cornerRadius(30)
                }
            }
        }
        .background(Color.gray.opacity(0.2))
        .cornerRadius(30)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

       
    
    private func tabItem(title: String, isSelected: Bool) -> some View {
        VStack {
            Text(title)
                .foregroundColor(isSelected ? .black : .gray)
            Capsule()
                .fill(isSelected ? Color.blue : Color.clear)
                .frame(height: 3)
                .padding(.horizontal, 30)
        }
    }
    
    // MARK: - Empty Placeholder
    private func emptyPlaceholder(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
        }
    }
    
    // MARK: - Collection View
    private var collectionView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(scanCollectionViewModel.scans.reversed(), id: \.id) { item in
                ZStack(alignment: .bottom) {
                    if let imageData = item.image, let uiImage = UIImage(data: imageData)?.fixOrientation() {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 200)
                            .clipped()
                            .cornerRadius(15)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 200)
                            .clipped()
                            .cornerRadius(15)
                    }
                    ZStack {
                        // Background Gradient Overlay
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 80) // Height of the gradient overlay
                        .cornerRadius(12)
                        
                        // Text Content
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown Name")
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(item.insectDesciption ?? "No Description")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                    }

                }
                .onTapGesture {
                    postViewModel.selectedCollection = item
                    navigationManager.push(.collectionDetailsScreen)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Posts View
    private var postsView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(postViewModel.userPosts.reversed(), id: \.postId) { item in
                ZStack(alignment: .bottom) {
                    if let imageUrl = item.imageUrl, !imageUrl.isEmpty {
                        MyRemoteImage(urlString: imageUrl)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 200)
                            .clipped()
                            .cornerRadius(15)
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width / 2 - 24, height: 200)
                            .clipped()
                            .cornerRadius(15)
                    }
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 80)
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading) {
                            Text(item.title ?? "Unknown Name")
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(item.descriptionText ?? "No Description")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        .padding(.bottom, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 10)
                    }
                }
                .onTapGesture {
                    DDLogDebug("Post tapped: \(item.title ?? "Unknown Title")")
                    
                    // Ensure these variables are properly set up
                    postViewModel.selectedUserPost = item
                    
                    // Push to detail screen
                    navigationManager.push(.userPostDetailScreen)
                }
            }
        }
        .padding(.top, 20)
    }


}

// MARK: - Preview
struct ProfileCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        let profile = UserResponse(userId: 1, uid: "123", name: "Jane Doe", email: "jane.doe@example.com", number: "1234567890", notificationToken: "", imageUrl: "", address: "123 Main St, Springfield", city: "Springfield", country: "USA", bio: "Nature lover", createdAt: 0.1, lat: 0.9, reported: false)
        
        let userViewModel = UserViewModel()
        let postViewModel = PostViewModel()
        
        return ProfileCollectionView(navigationManager: NavigationManager(),userViewModel: userViewModel, postViewModel: postViewModel, profile: profile)
    }
}
