//
//  InternetManager.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 29/01/2025.
//


   import Network

class InternetManager {

    // Singleton instance
    static let shared = InternetManager()

    private init() {}

    // Create a function to check for internet connectivity
    func isInternetAvailable(completion: @escaping (Bool) -> Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                completion(true)
            } else {
                completion(false)
            }
            monitor.cancel() // Stop monitoring after the check
        }
        
        monitor.start(queue: queue)
    }
}
