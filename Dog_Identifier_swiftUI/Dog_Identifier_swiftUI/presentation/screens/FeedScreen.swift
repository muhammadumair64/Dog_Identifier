import SwiftUI
import CocoaLumberjack

struct FeedScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var postViewModel: PostViewModel
    @ObservedObject var commonViewModel: CommonViewModel
    
    @State private var scrollProxy: ScrollViewProxy?
    @StateObject private var adsManager = AdsManager.shared
    @State  var showLoginAlert: Bool = false
    @State  var userId: Int? = 0
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollOffsetView(coordinateSpace: "scroll") { currentOffset in
                        let lastOffset = postViewModel.lastContentOffset

                        if currentOffset < lastOffset {
                            DDLogDebug("Scrolling Up - Hiding Bottom UI")
                            commonViewModel.showBottom = false
                        } else if currentOffset > lastOffset {
                            DDLogDebug("Scrolling Down - Showing Bottom UI")
                            commonViewModel.showBottom = true
                        }

                        postViewModel.lastContentOffset = currentOffset

                      }
                    LazyVStack(spacing: 15) {
                        ForEach(0..<postViewModel.posts.count, id: \.self) { index in
                            let post = postViewModel.posts[index]
                            let imageUrl = post.imageUrl ?? "defaultImageURL"
                            let profilePic = post.userImage ?? "https://www.rattanhospital.in/wp-content/uploads/2020/03/user-dummy-pic.png"
                            let userName = post.userName ?? "Anonymous"
                            let description = post.descriptionText ?? "No description available"
                            let time = post.createdAt.formattedDate()
                            let title = post.title ?? "Untitled"
                            let likeCount = Int(post.likeCount)
                            let commentCount = Int(post.commentCount)
                            let watcherCount = Int(post.watcherCount)

                            // MARK: - Post Cell
                            PostItemView(
                                image: imageUrl,
                                profilePic: profilePic,
                                name: userName,
                                description: title,
                                time: time,
                                like: likeCount,
                                comment: commentCount,
                                share: watcherCount
                            )
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                if post == postViewModel.posts.last {
                                    postViewModel.loadNextPageIfNeeded(currentItem: post)
                                }
                            }
                            .onTapGesture {
                                if(AdsCounter.shouldShowAd()){
                                    adsManager.interAdCallForScreen {
                                        postViewModel.selectedPost = post
                                        postViewModel.selectedIndex = index
                                        navigationManager.push(.postDetails)
                                    }
                                }else {
                                    postViewModel.selectedPost = post
                                    postViewModel.selectedIndex = index
                                    navigationManager.push(.postDetails)
                                }
                            }
                            .id(index)

                            // MARK: - Insert Ad Every 3 Items
                            if index != 0 && index % 3 == 0 {
                                AdSectionView(
                                    adUnitID: AdUnit.nativeMedia.unitId,
                                    layout: .medium,
                                    rootViewController: UIApplication.shared.rootVC
                                )
                            }
                        }
                    }
                    .padding(.bottom, 100)
                    .background {
                        ScrollDetector(
                            onScroll: { _ in },
                            onDraggingEnd: { _, _ in
                                commonViewModel.showBottom = true
                            },
                            onRefresh: {
                                DDLogDebug("Pull-to-Refresh Triggered")
                                postViewModel.refreshPosts()
                            }
                        )
                    }

                }
                .clipped()
                .onAppear {
                    scrollProxy = proxy
                    postViewModel.loadPosts()  // Initial data load
                }
                .onChange(of: postViewModel.selectedIndex) { newIndex in
                    if let index = newIndex {
                        DispatchQueue.main.async {
                            scrollProxy?.scrollTo(index, anchor: .top)
                        }
                    }
                }
            }
            if(commonViewModel.showBottom){
                // Floating Button
                CreatePostButton()
                    .padding(.bottom, 120)
                    .padding(.trailing, 17)
                    .onTapGesture{
                        if(userId != 0){
                            navigationManager.push(.createPost)
                        }else{
                            showLoginAlert =  true
                        }
            
                    }
            }
            

            // Center Loading Animation
            if postViewModel.isLoading {
                ZStack {
//                    Color.black.opacity(0.2)
//                        .ignoresSafeArea()
                    ProgressView("Loading...")
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .shadow(radius: 5)
                }
                .frame(maxWidth: .infinity,maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 15)
        .onAppear {
            guard let userId: Int = UserDefaultManager.shared.get(forKey: UserDefaultManager.Key.currentUser) else {
                DDLogError("User ID is not available.")
                return
            }
            self.userId = userId
            
            postViewModel.clearCreatePostData()
            // Scroll to the selected index if it's set
            if let selectedIndex = postViewModel.selectedIndex {
                DispatchQueue.main.async {
                    scrollProxy?.scrollTo(selectedIndex, anchor: .top)
                }
            }
        }
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("Login Required"),
                message: Text("You need to login to create a post."),
                primaryButton: .default(Text("Login"), action: {
                    commonViewModel.selectedTab = .profile
                }),
                secondaryButton: .cancel()
            )
        }
        .overlay(
            adsManager.isLoading ? LoadingDialogView() : nil
        )
    }
}


struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
struct ScrollOffsetView: View {
    let coordinateSpace: String
    let onScroll: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named(coordinateSpace)).minY)
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: onScroll)
    }
}


struct PostItemView: View {
    var image: String
    var profilePic: String
    var name: String
    var description: String
    var time: String
    var like: Int
    var comment: Int
    var share: Int

    var body: some View {
        VStack(alignment: .leading) {
            // HStack at the top
            HStack {
                if(profilePic == ""){
                    MyRemoteImage(urlString: "https://www.rattanhospital.in/wp-content/uploads/2020/03/user-dummy-pic.png")
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .padding(.leading, 15)
                }else {
                    MyRemoteImage(urlString: profilePic)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .padding(.leading, 15)
                }


                VStack(alignment: .leading) {
                    Spacer()
                    Text(name)
                        .font(.custom(FontHelper.bold.rawValue, size: 16))
                        .bold()
                        .foregroundColor(ColorHelper.darkText.color)
                        .padding(.bottom, 1)
                        .padding(.trailing, 20)
                        .lineLimit(1)

                    Text(time)
                        .font(.custom(FontHelper.medium.rawValue, size: 15))
                        .foregroundColor(ColorHelper.lightText.color)
                        .padding(.trailing, 20)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.leading, 10)
                Spacer()
//                Image(ImageResource.menu)
//                    .resizable()
//                    .frame(width: 30, height: 30)
//                    .tint(.white)
//                    .padding(.trailing, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: 70)
            .padding(.top, 10)

            Text(description)
                .font(.custom(FontHelper.bold.rawValue, size: 16))
                .foregroundColor(ColorHelper.darkText.color)
                .padding([.leading, .trailing], 15)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            ZStack(alignment: .bottom) {
                MyRemoteImage(urlString: image)
                    .cornerRadius(15)
                    .clipped()

                HStack {
                    LikeCommentView(image: ImageResource.like, count: String(like), iconSize: 20,width: 100, height: 35, textSize: 16)
                    LikeCommentView(image: ImageResource.message, count: String(comment), iconSize: 20, width: 100, height: 35, textSize: 16)
                    LikeCommentView(image: ImageResource.send, count: String(share), iconSize: 20, width: 100, height: 35, textSize: 16)
                }
                .padding(.bottom, 20)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 380, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ColorHelper.grayBG.color, lineWidth: 2)
        )
    }
}

struct CreatePostButton: View {
    var body: some View {
        HStack {
            Spacer()
            Image(ImageResource.createPost)
                .resizable()
                .frame(width: 17, height: 17)
                .tint(.white)
            Text("Create Post")
                .font(.custom(FontHelper.medium.rawValue, size: 16))
                .foregroundColor(.white)
                .padding(.leading, 5)
            Spacer()
        }
        .frame(width: 140, height: 50)
        .background(ColorHelper.primary.color)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 1)
        )
    }
}

struct LikeCommentView: View {
    var image: ImageResource
    var count: String
    var iconSize : CGFloat = 15
    var width : CGFloat = 65
    var height : CGFloat = 25
    var textSize : CGFloat = 13

    var body: some View {
        HStack {
            Spacer()
            Image(image)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .tint(.white)
            Text(count)
                .font(.custom(FontHelper.medium.rawValue, size: textSize))
                .foregroundColor(.white)
            Spacer()
        }
        .frame(width: width, height: height)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#424242"), Color(hex: "#404040"),
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .opacity(0.55)
        )
        .cornerRadius(20)  // Rounded corners
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#9E9E9E"), lineWidth: 1)
        )
    }
}

#Preview {
    FeedScreen(navigationManager: NavigationManager() ,postViewModel: PostViewModel(),commonViewModel: CommonViewModel())
}
