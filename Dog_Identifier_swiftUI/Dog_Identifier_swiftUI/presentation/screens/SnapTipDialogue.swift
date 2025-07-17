////
////  SnapTipDialogue.swift
////  Insect-detector-ios
////
////  Created by Mac Mini on 19/12/2024.
////
//
//import SwiftUI
//
//struct SnapTipDialogue: View {
//    @Binding var isShowingTipsView : Bool
//    let columns:  [GridItem] = [GridItem(.flexible()),
//                                GridItem(.flexible())]
//    
//    struct WrongPic: Identifiable {
//        let id = UUID()
//        let image: ImageResource
//        let text: String
//    }
//
//    let items = [
//        WrongPic(image: ImageResource.wrong1, text: "Too Far"),
//        WrongPic(image: ImageResource.wrong2, text: "Too Close"),
//        WrongPic(image: ImageResource.wrong3, text: "Blurry"),
//        WrongPic(image: ImageResource.wrong4, text: "Multi-Species")
//    ]
//
//    
//    var body: some View {
//        ZStack {
//            
//            VStack{
//                Text("Snap Tips")
//                    .font(Font.custom(FontHelper.extrabold.rawValue, size: 22))
//                    .multilineTextAlignment(.center)
//                    .padding(.top, 15)
//                    .padding(.horizontal, 20)
//                
//                Image(ImageResource.correctImg)
//                    .resizable()
//                    .frame(width: 270,height: 170)
//                
//                Text("The following will lead to poor results")
//                    .font(Font.custom(FontHelper.medium.rawValue, size: 18))
//                    .multilineTextAlignment(.center)
//                    .padding(.top, 25)
//                    .padding(.horizontal, 15)
//                
//                LazyVGrid(columns: columns) {
//                    ForEach(items) { item in
//                        WrongPicView(image: item.image, text: item.text)
//                    }
//                }
//                .padding()
//                
//            Button {
//                isShowingTipsView = false
//            }label: {
//                MainButton(title: NSLocalizedString("_gotIt", comment: ""), btnColor: ColorHelper.primary.color, width: 260,height: 55,radius: 30)
//                    .padding(.bottom,10)
//               }
//            }
//        }.frame(maxWidth:.infinity ,maxHeight: .infinity)
//            .background(Color(.systemBackground))
//            .cornerRadius(30)
//            .padding(.horizontal ,20)
//            .padding(.vertical ,40)
//            .shadow(radius: 20)
//            
//    }
//}
//
//#Preview {
//    SnapTipDialogue(isShowingTipsView: .constant(true))
//}
//
//struct WrongPicView: View {
//    var image : ImageResource
//    var text  : String
//    
//    var body: some View {
//        VStack {
//            Image(image)
//                .resizable()
//                .frame(width: 130,height: 80)
//            
//            Text(text)
//                .font(Font.custom(FontHelper.medium.rawValue, size: 15))
//                .multilineTextAlignment(.center)
//                .padding(.top, 5)
//                .padding(.horizontal, 15)
//            
//        }
//    }
//}
