import SwiftUI
import CocoaLumberjack

struct ScanningResultScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var commonViewModel: CommonViewModel
    @ObservedObject var postViewModel: PostViewModel
    @StateObject var scanCollectionViewModel = ScanCollectionViewModel()
    @State var isDetailsShowing = false
 
    @State private var showLoginAlert: Bool = false
    @State  var userId: Int? = 0
    
    var body: some View {
        VStack{
            ScrollView (.vertical , showsIndicators: false){
                LazyVStack(spacing: 0) {
                    // Header Image Section
                    HeaderImageView(cameraViewModel: cameraViewModel, navigationManager: navigationManager)

                    // Content Section
                    VStack(spacing: 16) {
                        // Title and Scan Again Button
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cameraViewModel.dogResponse?.name ?? "UnKnown")
                                    .font(Font.custom(FontHelper.extrabold.rawValue, size: 20))
                                    .fontWeight(.bold)

                                HStack{
                                    Text("Species: ")
                                        .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                                        .foregroundColor(ColorHelper.primaryBlue.color)
                                    Text("Dogs")
                                        .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                                        .foregroundColor(.gray)
                                }
                            
                            }

                            Spacer()

                            Button(action: {
                                // Scan Again action
                                navigationManager.pop()
                                navigationManager.push(.cameraScreen)
                            }) {
                                Text("Scan Again")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 13)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        .onAppear() {
                            saveResult()
                        }
                   
                        
                    
                        // Details Section
                        DetailsView( cameraViewModel: cameraViewModel,isDetailsShowing: $isDetailsShowing)
       
//                        NativeAdView(adType: .withoutMedia)
//                                 .frame(height: 200)
//                                .background(ColorHelper.primary.color.opacity(0.1))
//                                .cornerRadius(20)
//                                .padding(.horizontal ,15)
                
                        AdSectionView(
                            adUnitID: AdUnit.nativeMedia.unitId, // <-- your ad unit ID
                            layout: .medium,
                              rootViewController: UIApplication.shared.rootVC
                          )
                          .padding()
                        // More Images Section
                        MoreImagesView(cameraViewModel: cameraViewModel)
                  

                        // Characteristics Section
                        CharacteristicsView(cameraViewModel: cameraViewModel)
                        
                        // Classification Section
                        ClassificationView(cameraViewModel: cameraViewModel)
                        // "Did you know?" Title
                        HStack{
                            Text("Did you know?")
                                .font(Font.custom(FontHelper.bold.rawValue, size: 18))
                                .fontWeight(.bold)
                                .padding(.leading)
                        }.frame(maxWidth: .infinity ,alignment: .leading)
                        .padding(.leading, 5)
                    
                                  
                        // Lifespan Section
                        LifeSpanView(cameraViewModel: cameraViewModel)

                        
                       // What Does It Eat? Section
                        WhatDoesItEat(cameraViewModel: cameraViewModel)
                        
                        if let response = cameraViewModel.dogResponse {
                            VStack(spacing: 16) {
                                HabitSectionView(
                                    title: "Good Habits",
                                    habits: response.goodHabits,
                                    backgroundColor: Color.green.opacity(0.2)
                                )

                                HabitSectionView(
                                    title: "Bad Habits",
                                    habits: response.badHabits,
                                    backgroundColor: Color.red.opacity(0.2)
                                )
                            }
                            .padding(.horizontal)
                        }

                        LocationInfoView(cameraViewModel: cameraViewModel)
                        
               

                        
                       // EffectsViews(cameraViewModel: cameraViewModel)
                        
                        CreatePostBtn().onTapGesture {
                            if(userId != 0){
                                postViewModel.imageForPost = cameraViewModel.croppedImage
                                postViewModel.descriptionForPost = cameraViewModel.dogResponse?.details ?? ""
                                postViewModel.titleForPost = cameraViewModel.dogResponse?.name ?? ""
                                navigationManager.pop()
                                navigationManager.push(.createPost)
                  
                            }else{
                                showLoginAlert = true
                            }
                        
                        }

                    }
                    
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(30)
                    .offset(y: -30) // Lift the content over the header
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .edgesIgnoringSafeArea(.top)
            
        }
        .alert(isPresented: $showLoginAlert) {
            Alert(
                title: Text("Login Required"),
                message: Text("You need to log in to like or comment on this post."),
                primaryButton: .default(Text("Login"), action: {
                    commonViewModel.selectedTab = .profile
                    navigationManager.pop()
                    navigationManager.pop()
                }),
                secondaryButton: .cancel()
            )
        }
        .onAppear{
            
            var count = UserDefaultManager.shared.get(forKey: .freeScans) ?? 0
            DDLogDebug("My Scans are \(count)")
            if(count < 3){
                count += 1
                DDLogDebug("My Scans increase \(count)")
                UserDefaultManager.shared.set(count, forKey: .freeScans)
            }
            
            guard let userId: Int = UserDefaultManager.shared.get(forKey: UserDefaultManager.Key.currentUser) else {
                DDLogError("User ID is not available.")
                return
            }
            self.userId = userId
            

        }
        .background(Color.white)
    }
    
    
    private func saveResult(){
        let defaultImage = UIImage(named: "dummy_img") ?? UIImage()
        scanCollectionViewModel.saveScan(name: cameraViewModel.dogResponse?.name ?? "", description: cameraViewModel.dogResponse?.details ?? "" , image: cameraViewModel.croppedImage ?? defaultImage)
    }
}

struct CreatePostBtn: View {
    var body: some View {
        HStack {
            Spacer()
            Image(ImageResource.createPost)
                .resizable()
                .frame(width: 21, height: 21)
                .tint(.white)
            Text("Create Post Now")
                .font(.custom(FontHelper.medium.rawValue, size: 16))
                .foregroundColor(.white)
                .padding(.leading, 5)
            Spacer()
        }
        .frame(width: .infinity, height: 50)
        .background(ColorHelper.primary.color)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 1)
        )
        .padding(.horizontal , 50)
    }
}

struct HeaderImageView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @ObservedObject var navigationManager: NavigationManager
    var body: some View {
        ZStack(alignment: .top) {
            Image(uiImage:  cameraViewModel.croppedImage ?? UIImage(named: "dummy_img")!)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 280)
                .clipped()
            
            // Back and Share Buttons
            HStack {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image(ImageResource.resultBack)
                        .resizable()
                        .frame(maxWidth: 40, maxHeight: 40)
                        .foregroundColor(.white)
                }
                Spacer()
//                Button(action: {
//                    // Share button action
//                }) {
////                    Image(ImageResource.resultShare)
////                        .resizable()
////                        .frame(maxWidth: 40, maxHeight: 40)
////                        .foregroundColor(.white)
//                }
            }
            .padding(.top,40)
            .padding(.horizontal,20)
        }
    }
}

struct DetailsView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    @Binding var isDetailsShowing:Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(ImageResource.details)
                    .resizable()
                    .frame(maxWidth: 40, maxHeight: 40)
                
                Text("Details")
                    .font(Font.custom(FontHelper.bold.rawValue, size: 18))
                    .padding(.leading, 12)
                
            }
            VStack{
                Text(cameraViewModel.dogResponse?.details ?? "Unavailable")
                    .font(Font.custom(FontHelper.regular.rawValue, size: 16))
                    .foregroundColor(.gray)
                    .lineLimit(isDetailsShowing ? 1000 : 4)
        
                HStack{
                    Text(isDetailsShowing ? "Show less" : "Read More")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Image(isDetailsShowing ? ImageResource.upArrow : ImageResource.downArrowBlue)
                        .resizable()
                        .frame(maxWidth: 15, maxHeight: 10)
                }.onTapGesture {
                    isDetailsShowing.toggle()
                }
            }.frame( maxWidth: .infinity , alignment:.bottom)
            

        }
        .padding()
        .padding(.bottom ,20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ColorHelper.grayBG.color, lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct LifeSpanView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    var body: some View {
        // Safely unwrap and split the lifespan string
        let lifeSpan = cameraViewModel.dogResponse?.lifeSpan ?? ""
        let splitLifeSpan = lifeSpan.split(separator: "-")
        
        // Ensure we get two parts, or use default values if there are fewer parts
        let firstPart = splitLifeSpan.first.map { String($0) } ?? ""
        let secondPart = splitLifeSpan.dropFirst().first.map { String($0) } ?? ""
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // Icon
                Circle()
                    .fill(Color(hex: "#BEE4FF"))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(ImageResource.lifeSpan)
                            .font(.title3)
                            .foregroundColor(.blue)
                    )
                Text("Lifespan")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.leading, 5)
            
            HStack {
                Text("Average:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                // Display first part of life span
                Text(firstPart+" Years")
                    .font(.subheadline)
                    .foregroundColor(ColorHelper.darkText.color)
                
                Spacer()
                Image(ImageResource.vDivider)
                Spacer()
                
                Text("Maximum:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                // Display second part of life span
                Text(secondPart + " Years")
                    .font(.subheadline)
                    .foregroundColor(ColorHelper.darkText.color)
            }
            .padding(.horizontal, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure leading alignment
        .padding()
        .background(Color(hex: "#E5F4FF"))
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
}

struct HabitSectionView: View {
    let title: String
    let habits: [DogHabit]
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Font.custom(FontHelper.medium.rawValue, size: 18))
                .padding(.bottom, 4)
                .foregroundColor(.primary)

            ForEach(habits) { habit in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(Font.custom(FontHelper.medium.rawValue, size: 18))
                        .foregroundColor(.black)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.title)
                            .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                            .foregroundColor(ColorHelper.darkText.color)
                        Text(habit.description)
                            .font(Font.custom(FontHelper.regular.rawValue, size: 14))
                            .foregroundColor(ColorHelper.lightText.color)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}



struct CharacteristicRow: View {
    let title: String
    let value: String
    let backgroundColor: String

    var body: some View {
        ZStack(alignment: .leading) {
        VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.leading, 5)

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(ColorHelper.darkText.color)
                    .padding(.leading, 5)
                    .lineLimit(2) // Allow up to 2 lines
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 80, alignment: .leading)
        .background(Color(hex: backgroundColor))
        .cornerRadius(8)
        .padding(.vertical, 3)
    }

}

struct CharacteristicsView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(ImageResource.sizeIc)
                    .frame(maxWidth: 40, maxHeight: 40)
                
                Text("Characteristics")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                // Adult Size
                CharacteristicRow(
                    title: "Adult Size",
                    value: cameraViewModel.dogResponse?.characteristics.size.replacingOccurrences(of: "-9:", with: "+") ?? "unavailable"
                    ,
                    backgroundColor: "#FDE8FF"
                )
                
                // Colors
                if let characteristics = cameraViewModel.dogResponse?.characteristics {
                    let colorRows = zip(characteristics.colors, characteristics.colorCodes).map { colorName, colorCode in
                        ValueWithColor(value: colorName, color: colorCode)
                    }

                    if(!colorRows.isEmpty){
                        ColorRow(
                            title: "Colors",
                            valuesWithColors: colorRows
                        )
                    }
                }

                
             //    Habitat
                CharacteristicRow(
                    title: "Bite Force",
                    value: (cameraViewModel.dogResponse?.biteForce.isEmpty == false ? "\(cameraViewModel.dogResponse?.biteForce ?? "200") psi" : "200 psi"),
                    backgroundColor: "#D9DFFF"
                )
            }

            
        }.padding()
        
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(ColorHelper.grayBG.color, lineWidth: 2)
            )
            .padding(.horizontal)
    }
}
struct ColorRow: View {
    let title: String
    let valuesWithColors: [ValueWithColor]

    var gridItems: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
    }

    private func getForegroundColor(for item: ValueWithColor) -> Color {
        // Adjust text color based on background
        if item.color.uppercased() == "#FFFFFF" || item.value.contains("Yellow") {
            return .black
        } else {
            return .white
        }
    }

    private func colorLabel(for item: ValueWithColor) -> some View {
        Text(item.value.replacingOccurrences(of: ";", with: ""))
            .font(Font.custom(FontHelper.medium.rawValue, size: 15))
            .fontWeight(.bold)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(hex: item.color))
            .foregroundColor(getForegroundColor(for: item))
            .cornerRadius(10)
            .lineLimit(1)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Image(ImageResource.resultFieldBg)
                .resizable()
                .frame(maxHeight: CGFloat((gridItems.count + 3)/4) * 150)
                .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                    .padding(.leading, 5)

                LazyVGrid(columns: gridItems, spacing: 2) {
                    ForEach(valuesWithColors, id: \.id) { item in
                        colorLabel(for: item)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 3)
    }
}



struct ClassificationView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(ImageResource.classification)
                    .foregroundColor(.blue)
                Text("Classification")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                CharacteristicRow(title: "Genus", value: cameraViewModel.dogResponse?.classification.genus ?? "unavailable",backgroundColor: "#D9DFFF")
                CharacteristicRow(title: "Family", value: cameraViewModel.dogResponse?.classification.family ?? "unavailable",backgroundColor: "#FFEFD4")
                CharacteristicRow(title: "Order", value: cameraViewModel.dogResponse?.classification.order ?? "unavailable",backgroundColor: "#DCFFFB")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(ColorHelper.grayBG.color, lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct WhatDoesItEat: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    // Diet items fetched from the cameraViewModel
    var dietItems: [DietItem] {
        // Assuming cameraViewModel has a property that holds diet information
        // Replace this with the actual property from cameraViewModel
        return cameraViewModel.dogResponse?.diet ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Circle()
                    .fill(Color.pink.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(ImageResource.dogFood) // Replace with your icon
                            .resizable()
                            .foregroundColor(.pink)
                            .frame(width: 30, height: 30)
                    )
                
                Text("What does it eat?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Diet details rendered dynamically
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(dietItems) { item in
                    DietItemView(text: item.text, color: "#E3B5C4")
                }
            }
            .padding(.leading, 20) // Aligns with the icon
        }
        .padding()
        .background(Color(hex: "#FBE8EE"))
        .cornerRadius(15)
        .padding(.horizontal, 20)
    }
}
struct DietItemView: View {
    let text: String
    let color: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.black)
        }
    }
}


struct LocationInfoView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(ImageResource.worldIc)
                    .resizable()
                    .frame(maxWidth: 40, maxHeight: 40)
                  
                Text("Where to find?")
                    .font(Font.custom(FontHelper.extrabold.rawValue, size: 18))
            }
            .padding(.horizontal, 20) // Padding for the top HStack (image + title)
            
            HStack(alignment: .top) {
                Text("Found in:")
                    .font(Font.custom(FontHelper.bold.rawValue, size: 15))
                    .foregroundColor(Color(hex: "#FFB618"))
                
                // Handle the countries array properly
                Text(cameraViewModel.dogResponse?.countries.joined(separator: ", ") ?? "Unavailable")
                    .font(Font.custom(FontHelper.medium.rawValue, size: 15))
                
                Spacer() // To push the text to the left, you can use Spacer here
            }
            .padding(.horizontal, 20) // Horizontal padding for the bottom HStack
        }
        .padding(.vertical) // Vertical padding for the whole VStack
        .frame(maxWidth: .infinity) // Ensure the view takes up full width
        .background(Color(hex: "#FFF3E5"))
        .cornerRadius(15)
        .padding(.horizontal, 20) // Outer horizontal padding for the whole view
    }
}

// Stage model
//struct GrowthLifecycleView: View {
//    // Pass a list of stages dynamically
//    @ObservedObject var cameraViewModel: CameraViewModel
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            HStack {
//                Image(ImageResource.incompleteIc)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 50, height: 50)
//                
//                VStack(alignment: .leading) {
//                    Text(
//                        cameraViewModel.dogResponse?.biteForce
//             
//                            ?? "Incomplete Metamorphosis"
//                    )
//                    .font(.title3)
//                    .fontWeight(.semibold)
//                    .lineLimit(1)
//
//                    Text( cameraViewModel.dogResponse?.lifecycleDescription ?? "Insect hatch and grow through molting")
//                        .font(Font.custom(FontHelper.medium.rawValue, size: 13))
//                        .foregroundColor(.gray)
//                }
//                .frame(maxWidth: .infinity, alignment: .leading)
//            }
//
//            // Use LazyVStack to dynamically render stages
//            if let growthStages = cameraViewModel.dogResponse?.growthStages, !growthStages.isEmpty {
//                // If growthStages is not nil and not empty
//                ForEach(growthStages, id: \.title) { stage in
//                    StageView(
//                        title: stage.title,
//                        description: stage.description
//                    )
//                }
//            } else {
//                // If growthStages is nil or empty
//                Text("No growth stages available")
//                    .foregroundColor(.gray)
//            }
//        }
//        .padding()
//        .background(Color(hex: "#F4F2FF"))
//        .cornerRadius(15)
//        .padding(.horizontal, 20)
//    }
//}
struct StageView: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top) {
            Circle()
                .fill(Color(hex: "#CEC5FF"))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(ImageResource.spiderIcResult)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                )
    
            
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(ColorHelper.darkText.color)
            }.padding(.top,10)
        }
        .cornerRadius(15)
        .padding(.vertical,7)
    }
}

// Preview
#Preview {
    ScanningResultScreen(navigationManager: NavigationManager(), cameraViewModel: CameraViewModel(),commonViewModel: CommonViewModel(),postViewModel: PostViewModel(), scanCollectionViewModel: ScanCollectionViewModel())
}


struct MoreImagesView: View {
    @ObservedObject var cameraViewModel: CameraViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(ImageResource.moreImages)
                    .frame(maxWidth: 40, maxHeight: 40)
                
                Text("More Images")
                    .font(.headline)
            }.padding(.bottom,15)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(cameraViewModel.images, id: \.id) { image in
                        MyRemoteImage(urlString: image.largeImageURL)
                            .frame(width: 130, height: 130)
                            .scaledToFill()
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 8)
            }.frame(maxHeight: 150)

        }
        .frame(maxHeight: 200)
        
        
        .padding(.horizontal)
        .padding(.vertical , 10)
    }
}




//struct EffectsViews: View {
//    @ObservedObject var cameraViewModel: CameraViewModel
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack(spacing: 8) {
//                Image(ImageResource.effectsIc)
//                    .font(.title)
//                    .foregroundColor(.black)
//                Text("Effects")
//                    .font(.title3)
//                    .fontWeight(.semibold)
//            }
//            
//            VStack(alignment: .leading, spacing: 8) {
//                // Safely unwrap venomInfo and check for venomous/ non-venomous
//                if let venomInfo = cameraViewModel.dogResponse?.venomInfo.lowercased(),
//                   venomInfo.contains("non venomous") || venomInfo.contains("not") || venomInfo.contains("non-venomous") || venomInfo.contains("not venomous") {
//         
//                    HStack {
//                        Circle()
//                            .fill(Color.green)
//                            .frame(width: 10, height: 10)
//                        Text("Green Badge:")
//                            .fontWeight(.semibold)
//                            .foregroundColor(Color.green)
//                        Text("Non-Venomous")
//                            .foregroundColor(ColorHelper.darkText.color)
//                    }
//                } else {
//                    HStack {
//                        Circle()
//                            .fill(Color.red)
//                            .frame(width: 10, height: 10)
//                        Text("Red Badge:")
//                            .fontWeight(.semibold)
//                            .foregroundColor(Color.red)
//                        Text("Venomous")
//                            .foregroundColor(ColorHelper.darkText.color)
//                    }
//                }
//            }
//
//            
//            Text("On Humans")
//                .font(.headline)
//                .fontWeight(.semibold)
//            
//            Text(cameraViewModel.dogResponse?.venomInfo ?? "Unavailable")
//                .font(.subheadline)
//                .foregroundColor(ColorHelper.darkText.color)
//
//            //            Button(action: {}) {
////                HStack(spacing: 4) {
////                    Text("Read More")
////                        .font(.subheadline)
////                        .foregroundColor(.blue)
////                    Image(systemName: "chevron.down")
////                        .font(.subheadline)
////                        .foregroundColor(.blue)
////                }
////            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(Color.white)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
//        .padding(.horizontal,20)
//     
//    }
//}
