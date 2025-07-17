//
//  CommonViewModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 22/01/2025.
//

import Foundation
import CocoaLumberjack

enum Tab {
    case home
    case feeds
    case identify
    case profile
    
}

enum InsectSelection {
    case ants
    case bees
    case beetles
    case butterflies
    case insects
    case spiders
}

class CommonViewModel: ObservableObject {
    @Published  var selectedTab: Tab = .home
    @Published  var selectedInsects: InsectSelection = .ants
    @Published  var  selectedInsectForDetail : Insect? = nil
    @Published  var selectedSideMenuTab = 0
    @Published var showBottom = true
    
    @Published var exploreList:[ExploreItemDataClass] = []

    @Published var blogs: [Blog] = []
    @Published var selectedDetail: Detail?
    
    @Published var listOfAnts: [Insect] = []
    @Published var listOfBees: [Insect] = []
    @Published var listOfBeetles: [Insect] = []
    @Published var listOfButterflies: [Insect] = []
    @Published var listOfInsects: [Insect] = []
    @Published var listOfSpiders: [Insect] = []
    
    @Published var dogs: [Dog] = []
    @Published var selectedDog : Dog? = nil
     @Published var isLoading: Bool = false
     @Published var errorMessage: String?

    @Published var isUserLogin =  false
    @Published var isShowingDialog = false
 init() {
     loadExploreInsect()
     loadBlogs()
     getAnts()
     getBees()
     getBeetles()
     getInsects()
     getSpiders()
     getButterflies()
 }
 
 private func loadExploreInsect() {
     exploreList = [
        ExploreItemDataClass(id: 1, image: "ant", title: "Ant", subtitle: "Formicidae",colorString: "#DCF5DC"),
        ExploreItemDataClass(id: 2, image: "bee", title: "Bee or wasp", subtitle: "Vespidae",colorString: "#FDE8FF"),
        ExploreItemDataClass(id: 3, image: "beetle", title: "Beetle", subtitle: "Coleoptera",colorString: "#FFF4F4"),
        ExploreItemDataClass(id: 4, image: "butterfly", title: "Butterfly", subtitle: "Lepidoptera",colorString: "#EBF2FF"),
        ExploreItemDataClass(id: 5, image: "most_common", title: "Most Common", subtitle: "Insecta",colorString: "#FFEFD4"),
        ExploreItemDataClass(id: 6, image: "spider", title: "Spider", subtitle: "Araneae",colorString: "#FFF9E8")
     
 
   
         
//         ExploreItemDataClass(id: 6, image: "grasshoper", title: "Grasshopper", subtitle: "Caelifera",colorString: "#FFE1ED"),
//         ExploreItemDataClass(id: 7, image: "tree_bug", title: "Tree Bug", subtitle: "Insecta",colorString: "#D9DFFF"),
//         ExploreItemDataClass(id: 8, image: "milipode", title: "Millipede", subtitle: "Diplopoda",colorString: "#DCFFFB"),
//         ExploreItemDataClass(id: 3, image: "moth", title: "Moth", subtitle: "Lepidoptera",colorString: "#F8F8F8")
     ]
 }
 

 private func loadBlogs() {
     guard let url = Bundle.main.url(forResource: "main_blogs_recycler", withExtension: "json") else {
         print("JSON file not found")
         return
     }

     do {
         let data = try Data(contentsOf: url)
         let decodedResponse = try JSONDecoder().decode(BlogResponse.self, from: data)
         blogs = decodedResponse.Blogs
     } catch {
         print("Failed to load or decode JSON: \(error)")
     }
 }

    func fetchDetail(for id: String) {
        if let url = Bundle.main.url(forResource: "blogs_details", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decodedDetails = try JSONDecoder().decode([String: [Detail]].self, from: data)
                self.selectedDetail = decodedDetails["Details"]?.first(where: { $0.id == id })
            } catch {
                DDLogError("Failed to parse details JSON: \(error.localizedDescription)")
            }
        } else {
            DDLogError("Details JSON file not found")
        }
    }
    
    // Function to load a specific insect JSON file from the bundle
    func loadInsectData(from fileName: String, completion: @escaping (Result<[Insect], Error>) -> Void) {
        // Get the file URL from the app's bundle
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "File not found."])))
            return
        }
        
        // Load the JSON data
        do {
            let jsonData = try Data(contentsOf: fileURL)
            
            // Decode the JSON data
            let decoder = JSONDecoder()
            let myResponse = try decoder.decode(InsectsResponse.self, from: jsonData)
            completion(.success(myResponse.Insect))
            
        } catch {
            completion(.failure(error))
        }
    }
    
    
    func getAnts(){
        // Example Usage: Fetching Ants Data
        loadInsectData(from: "ants") { result in
            switch result {
            case .success(let insects):
                DDLogDebug("Ants data loaded: \(insects.count)")
                self.listOfAnts.removeAll()
                self.listOfAnts.append(contentsOf: insects)
                
                // You can update your UI or handle the data here
            case .failure(let error):
                print("Failed to load ants data: \(error.localizedDescription)")
            }
        }
    }
    
    func getBees(){
        // Example Usage: Fetching Ants Data
        loadInsectData(from: "bees") { result in
            switch result {
            case .success(let insects):
                DDLogDebug("bees data loaded: \(insects.count)")
                // You can update your UI or handle the data here
                self.listOfBees.removeAll()
                self.listOfBees.append(contentsOf: insects)
                
            case .failure(let error):
                print("Failed to load ants data: \(error.localizedDescription)")
            }
        }
    }
    
    func getBeetles(){
        // Example Usage: Fetching Ants Data
        loadInsectData(from: "beetles") { result in
            switch result {
            case .success(let insects):
                DDLogDebug("beetles data loaded: \(insects.count)")
                // You can update your UI or handle the data here
                self.listOfBeetles.removeAll()
                self.listOfBeetles.append(contentsOf: insects)
                
            case .failure(let error):
                print("Failed to load ants data: \(error.localizedDescription)")
            }
        }
    }
    
    func getButterflies(){
        // Example Usage: Fetching Ants Data
        loadInsectData(from: "butterflies") { result in
            switch result {
            case .success(let insects):
                DDLogDebug("butterflies data loaded: \(insects.count)")
                // You can update your UI or handle the data here
                self.listOfButterflies.removeAll()
                self.listOfButterflies.append(contentsOf: insects)
            case .failure(let error):
                print("Failed to load ants data: \(error.localizedDescription)")
            }
        }
    }
    
    func getInsects(){
        // Example Usage: Fetching Ants Data
        loadInsectData(from: "insects") { result in
            switch result {
            case .success(let insects):
                DDLogDebug("Insect data loaded: \(insects.count)")
                // You can update your UI or handle the data here
                self.listOfInsects.removeAll()
                self.listOfInsects.append(contentsOf: insects)
            case .failure(let error):
                print("Failed to load ants data: \(error.localizedDescription)")
            }
        }
    }
    
    func getSpiders(){
        // Example Usage: Fetching Ants Data
        loadInsectData(from: "spiders") { result in
            switch result {
            case .success(let insects):
                DDLogDebug("spiders data loaded: \(insects.count)")
                // You can update your UI or handle the data here
                self.listOfSpiders.removeAll()
                self.listOfSpiders.append(contentsOf: insects)
            case .failure(let error):
                print("Failed to load ants data: \(error.localizedDescription)")
            }
        }
    }

    func fetchDogs() {
        isLoading = true
        Task {
            do {
                DDLogVerbose("Fetching dog data...")
                let result = try await DogDataLoader.getDogsData()
                DispatchQueue.main.async {
                    self.dogs = result
                    self.isLoading = false
                    DDLogDebug("MY DOG LIST IS = \(result.count)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    DDLogError("Error fetching dog data: \(error.localizedDescription)")
                }
            }
        }
    }
}
