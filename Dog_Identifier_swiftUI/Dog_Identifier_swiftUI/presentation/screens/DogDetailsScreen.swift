//
//  DogDetailsScreen.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 30/04/2025.
//

import SwiftUI

struct DogDetailsView: View {
    @ObservedObject var navigationManager: NavigationManager
    @StateObject var commonViewModel : CommonViewModel
    @State private var isShareSheetPresented = false
    
    var body: some View {
        VStack(spacing: 1){
            // Header Image
            ZStack(alignment: .topLeading) {
                Image(nameToAssetName(commonViewModel.selectedDog?.breedName ?? "american_english_coonhound")) // Optionally replace with dynamic image mapping
                    .resizable()
                    .frame(width: .infinity,height: 300)
                    .clipped()
                    .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                
                HStack {
                    Button(action: {
                        navigationManager.pop()
                    }) {
                        Image(ImageResource.resultBack)
                            .padding()
                    }
                    Spacer()
                    Button(action: {
                        isShareSheetPresented = true
                    }) {
                        Image(ImageResource.resultShare)
                            .padding()
                    }
                    .sheet(isPresented: $isShareSheetPresented) {
                        if let image = UIImage(named: nameToAssetName(commonViewModel.selectedDog?.breedName ?? "american_english_coonhound")) {
                            let title = commonViewModel.selectedDog?.breedName
                            let description = commonViewModel.selectedDog?.dogBreedDetailList.first?.detail ?? "No description available."
                            let combinedText = "\(String(describing: title))\n\n\(description)"
                            ShareSheet(activityItems: [image, combinedText])
                        } else {
                            Text("Image not found.")
                        }
                    }

                }
                .padding()
                .padding(.top,30)
            }.frame(width: .infinity,height: 300)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(commonViewModel.selectedDog?.breedName ?? "american english coonhound")
                        .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                    
                    // Info Cards
                    if(commonViewModel.selectedDog !=  nil){
                        DogInfoGridView(dog: commonViewModel.selectedDog!)
                    }
                    
                    AdSectionView(
                        adUnitID: AdUnit.nativeNoMedia.unitId, // <-- your ad unit ID
                        layout: .small,
                          rootViewController: UIApplication.shared.rootVC
                      )
            

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(ImageResource.descriptionDetailsIc)
                                .font(.title3)
                                .foregroundColor(.orange)
                                .padding(.trailing,10)
                            Text("Description")
                                .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                        }
                        .padding(.bottom, 5)

                        Text(commonViewModel.selectedDog?.dogBreedDetailList.first?.detail ?? "No description available.")
                            .font(Font.custom(FontHelper.regular.rawValue, size: 13))
                            .foregroundColor(.gray)
                    }

                    // Other Details
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(ImageResource.otherDetailsIc)
                                .font(.title3)
                                .foregroundColor(.orange)
                                .padding(.trailing,10)
                            
                            Text("Other Details")
                                .font(Font.custom(FontHelper.medium.rawValue, size: 16))
                        }
                        .padding(.bottom, 5)
                        if(commonViewModel.selectedDog !=  nil){
                            OtherDetailsView(dog: commonViewModel.selectedDog!)
                        }
                        
                    }
                }
                .padding(.horizontal,20)
            }
        }
        .navigationBarHidden(true)
    }
    
    private func nameToAssetName(_ name: String) -> String {
        return name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


struct DogInfoGridView: View {
    let dog: Dog

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                InfoCardView(iconName: ImageResource.familyBelong, title: "Family Belong", subtitle: dog.breedGroup)
                InfoCardView(iconName: ImageResource.sizeDetailIc, title: "Size", subtitle: dog.size)
            }

            HStack(spacing: 10) {
                InfoCardView(iconName: ImageResource.lifeSpanDetail, title: "Life Span", subtitle: dog.lifeSpan)
                InfoCardView(iconName: ImageResource.colorsDetails, title: "Colors", subtitle: dog.colors)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


struct InfoCardView: View {
    let iconName: ImageResource
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 35, height: 35)

                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(Color.brown)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.custom(FontHelper.medium.rawValue, size: 11))
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(Font.custom(FontHelper.regular.rawValue, size: 9))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.horizontal, 10)
        .frame(height: 60) // Fixed height
        .background(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct OtherDetailsView: View {
    let dog: Dog

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            DetailRow(label: "Other Names", value: dog.otherNames)
            DetailRow(label: "Temperament", value: dog.temperament)
            DetailRow(label: "Pattern Types", value: dog.type)
            DetailRow(label: "Litter Size", value: dog.litterSize)
            DetailRow(label: "Height", value: dog.height)
            DetailRow(label: "Weight", value: dog.weight)

            Spacer()
        }
    }
}

struct DetailRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .frame(width: 110, alignment: .leading)
                .font(Font.custom(FontHelper.medium.rawValue, size: 14))
                .foregroundColor(.black)

            Text(":")
                .font(Font.custom(FontHelper.medium.rawValue, size: 14))
                .foregroundColor(.black)
                .padding(.trailing,10)

            Text(value)
                .font(Font.custom(FontHelper.regular.rawValue, size: 12))
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
        }
    }
}



#Preview {
    let sampleDog = Dog(
        id: 1,
        breedName: "Labrador Retriever",
        breedLabel: "Lab",
        otherNames: "Labby, Labbie",
        popularity: "High",
        origin: "UK",
        breedGroup: "Sporting",
        size: "Medium",
        type: "Pure Bred",
        lifeSpan: "10 - 12 years",
        temperament: "Friendly, Outgoing",
        height: "22-24 inches (Male), 21-23 inches (Female)",
        weight: "65-80 pounds (Male), 55-70 pounds (Female)",
        colors: "Black, Yellow, Chocolate",
        litterSize: "6-8 puppies",
        puppyPrice: "$800 - $1200",
        puppyNames: [],
        dogBreedDetailList: [DogBreedDetail(id: 1, title: "Overview", detail: "The Labrador Retriever is a friendly...", breedId: 1)],
        characteristics: []
    )
    
    DogDetailsView(navigationManager: NavigationManager(), commonViewModel: CommonViewModel())
}
