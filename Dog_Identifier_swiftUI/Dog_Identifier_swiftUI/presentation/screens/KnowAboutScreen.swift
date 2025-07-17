//
//  KnowAboutScreen.swift
//  Dog_Identifier_swiftUI
//
//  Created by Mac Mini on 30/04/2025.
//

import SwiftUI

struct KnowAboutScreen: View {
    @ObservedObject var navigationManager: NavigationManager
    @ObservedObject var commonViewModel: CommonViewModel
    @ObservedObject var cameraViewModel: CameraViewModel
    @StateObject private var adsManager = AdsManager.shared
    @State private var searchText = ""

    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // Filtered list based on search
    private var filteredDogs: [Dog] {
        if searchText.isEmpty {
            return commonViewModel.dogs
        } else {
            return commonViewModel.dogs.filter {
                $0.breedName.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(ImageResource.backBtn)
                    .foregroundColor(.black)
                    .onTapGesture {
                        navigationManager.pop()
                    }
                Text("Know About Dogs")
                    .font(Font.custom(FontHelper.regular.rawValue, size: 20))
                    .foregroundColor(.black)
                    .padding(.leading,10)
                Spacer()
            }
            .padding(.horizontal)

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search...", text: $searchText)
                    .font(Font.custom(FontHelper.regular.rawValue, size: 16))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color.white)
            )
            .padding(.horizontal)

            // Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredDogs) { dog in
                        if(isImageAvailable(nameToAssetName(dog.breedName))){
                            DogCardView(dog: dog)
                                .onTapGesture {
                                    if(AdsCounter.shouldShowAd()){
                                        AdsManager.shared.interAdCallForScreen(onAction: {
                                            commonViewModel.selectedDog = dog
                                            navigationManager.push(.dogDetailScreen)
                                        })
                                    }else{
                                        commonViewModel.selectedDog = dog
                                        navigationManager.push(.dogDetailScreen)
                                    }
                   
                                }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40) // Extra bottom spacing
            }
        }
        .padding(.top)
        .overlay (
            adsManager.isLoading ? LoadingDialogView() : nil
        )
    }
    
    func isImageAvailable(_ name: String) -> Bool {
        return UIImage(named: name) != nil
    }

    private func nameToAssetName(_ name: String) -> String {
        return name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
    
}

struct DogCardView: View {
    let dog: Dog

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Image(nameToAssetName(dog.breedName))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), .clear]),
                    startPoint: .bottom,
                    endPoint: .center
                )
                .frame(width: geometry.size.width, height: geometry.size.height)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dog.breedName)
                        .font(Font.custom(FontHelper.regular.rawValue, size: 14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(dog.breedGroup)
                        .font(Font.custom(FontHelper.regular.rawValue, size: 10))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .aspectRatio(1.2, contentMode: .fit) // Adjust aspect ratio for layout
    }

    private func nameToAssetName(_ name: String) -> String {
        return name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
    }
}

#Preview {
    KnowAboutScreen(navigationManager: NavigationManager(), commonViewModel: CommonViewModel(),cameraViewModel: CameraViewModel())
}
