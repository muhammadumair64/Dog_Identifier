//
//  BlogsDetailScreen.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 01/05/2025.
//

import SwiftUI

struct BlogsDetailScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var commonViewModel: CommonViewModel
    @State var  myPara : AttributedString = ""
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Custom Navigation Bar
                    NavigationBarViewForBlog(navigationManager: navigationManager, title: "Blog").zIndex(100)
                    
                    // Main Image
                    mainImage(myImage: commonViewModel.selectedDetail?.image ?? "")
                        .padding(.top, 20)
                    
                    // Info Section
                    infoSection(
                        title: commonViewModel.selectedDetail?.Title ?? "",
                        author: commonViewModel.selectedDetail?.Author ?? "",
                        source: commonViewModel.selectedDetail?.Source ?? "",
                        date: commonViewModel.selectedDetail?.Date ?? ""
                    )
                    AdSectionView(
                        adUnitID: AdUnit.nativeMedia.unitId, // <-- your ad unit ID
                        layout: .medium,
                          rootViewController: UIApplication.shared.rootVC
                      )
       
    //                // Description Section
                
                    descriptionSection(details: myPara)
                            .padding(.top, 20)
                  
                }
                .padding(.horizontal, 20) // Add consistent padding
            }
            .onAppear{
                DispatchQueue.global(qos: .background).async {
                    var myDetails = commonViewModel.selectedDetail?.para ?? ""
                    myPara = myDetails.htmlToString(size: 16)
                }
            }
    }
}

struct NavigationBarViewForBlog: View {
    @ObservedObject var navigationManager: NavigationManager
    let title: String
    
    var body: some View {
        HStack {
            HStack {
                Button(action: {
                    navigationManager.pop()
                }) {
                    Image("backBtn")
                        .foregroundColor(.orange)
                        .font(.title2)
                }
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .padding(.leading,20)
                Spacer()
            }.zIndex(100)
            Spacer()
//            Button(action: {
//                // Handle share action
//            }) {
//                Image(systemName: "square.and.arrow.up")
//                    .foregroundColor(.orange)
//                    .font(.title2)
//            }
        }
        .padding()
    
    }
}
struct mainImage: View {
    var myImage: String
    var body: some View {
        ZStack{
            Image(myImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: 250)
                .clipped()
                .cornerRadius(10)
        }

    }
}

struct infoSection: View {
    var title: String
    var author: String
    var source :String
    var date: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title)
                .font(Font.custom(FontHelper.bold.rawValue, size: 20))
            
            // Author
            HStack {
                Text("Author:")
                    .font(Font.custom(FontHelper.bold.rawValue, size: 16))
                Spacer()
                Text(author)
                    .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                    .foregroundColor(.gray)
            }
            // Author
            HStack {
                Text("Source:")
                    .font(Font.custom(FontHelper.bold.rawValue, size: 16))
                Spacer()
                Text(source)
                    .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                    .foregroundColor(.gray)
            }
            
            // Date
            HStack {
                Text("Date:")
                    .font(Font.custom(FontHelper.bold.rawValue, size: 16))
                Spacer()
                Text(date)
                    .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct descriptionSection: View {
    var details: AttributedString = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 10) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.blue)
                Text("Description")
                    .font(Font.custom(FontHelper.bold.rawValue, size: 20))
            }
            Text(details)
                .foregroundColor(.gray)
        }
    }
}

struct BlogsDetailScreen_Previews: PreviewProvider {
    static var previews: some View {
        BlogsDetailScreen(navigationManager: NavigationManager(), commonViewModel: CommonViewModel())
    }
}
