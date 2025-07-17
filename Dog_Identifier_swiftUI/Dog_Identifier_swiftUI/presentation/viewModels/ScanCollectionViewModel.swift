//
//  ScanCollectionViewModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 06/01/2025.
//


import UIKit
import CoreData

class ScanCollectionViewModel: ObservableObject {
    @Published var scans: [ScanCollection] = []
   

    private let coreDataManager = CoreDataManager.shared

    // MARK: - Scan Methods
    func saveScan(name: String, description: String?, image: UIImage) {
        coreDataManager.saveScan(name: name, description: description, image: image)
        fetchScans() // Fetch updated scans list
    }
    func fetchScans() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Perform background task, such as fetching data from Core Data
            let scans = self.coreDataManager.fetchAllScans()
            
            // Once the data is fetched, switch to the main thread to update UI
            DispatchQueue.main.async {
                self.scans = scans
                print("Fetched scans: \(scans)")
            }
            
        }
    }

    func deleteScan(scan: ScanCollection) {
        coreDataManager.deleteScan(scan)
        fetchScans() // Refresh the list
    }
}
