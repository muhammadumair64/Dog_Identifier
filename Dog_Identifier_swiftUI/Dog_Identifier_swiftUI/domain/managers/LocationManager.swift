import CoreLocation
import SwiftUI
import CocoaLumberjack

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private var locationManager = CLLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String? // To store the full address
    @Published var latitude: Double? // Latitude
    @Published var longitude: Double? // Longitude
    @Published var error: String? // Error string
    @Published var isFetchingLocation: Bool = false // Indicates if location is being fetched
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()  // Request permission here
    }
    
    // Fetch location once
    func fetchLocation() {
        checkAuthorization()
        
        // Check if location services are enabled and if permissions are granted
        if CLLocationManager.locationServicesEnabled() {
            isFetchingLocation = true // Start fetching location
            locationManager.requestLocation()  // Request a single location update
        } else {
            error = "Location services are not enabled. Please enable them in Settings."
            objectWillChange.send() // Notify the view of the state change
        }
    }
    
    // CLLocationManagerDelegate method to handle location updates (single location update)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isFetchingLocation = false // Stop fetching location
        
        if let newLocation = locations.last {
            self.currentLocation = newLocation
            self.latitude = newLocation.coordinate.latitude  // Get latitude
            self.longitude = newLocation.coordinate.longitude  // Get longitude
            
            fetchAddressFromCoordinates(location: newLocation) // Reverse geocoding to get the address
        }
    }
    
    // CLLocationManagerDelegate method to handle errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isFetchingLocation = false // Stop fetching location
        
        if let error = error as? CLError {
            switch error.code {
            case .denied:
                self.error = "Location Permission Denied"
                objectWillChange.send() // Notify the view about the error change
                DDLogError("Location Permission Denied") // Logging the denial error
            case .locationUnknown:
                self.error = "Location Unknown"
                objectWillChange.send() // Notify the view about the error change
                DDLogError("Location Unknown Error")
            default:
                self.error = error.localizedDescription
                objectWillChange.send() // Notify the view about the error change
                DDLogError("Location Error: \(error.localizedDescription)")
            }
        }
    }
    
    // Reverse geocoding to convert coordinates into a human-readable address
    private func fetchAddressFromCoordinates(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            if let error = error {
                self?.error = "Error with geocoding: \(error.localizedDescription)"
                self?.objectWillChange.send() // Notify the view about the error change
                DDLogError("Geocoding Error: \(error.localizedDescription)") // Logging geocoding error
                return
            }
            
            if let placemark = placemarks?.first {
                var addressString = ""
                
                // Check if there's a name (like "Mayo Street")
                if let name = placemark.name {
                    addressString += name // This would typically include street name, like "Mayo Street"
                }
                
                // Add locality (usually city)
                if let locality = placemark.locality {
                    if !addressString.isEmpty { addressString += ", " }
                    addressString += locality // City or locality
                }
                
                // Add administrative area (province or state)
                if let administrativeArea = placemark.administrativeArea {
                    if !addressString.isEmpty { addressString += ", " }
                    addressString += administrativeArea // Province or state
                }
                
                // Add country
                if let country = placemark.country {
                    if !addressString.isEmpty { addressString += ", " }
                    addressString += country // Country
                }
                
                // Set the full address or fallback to a default if not found
                self?.currentAddress = addressString.isEmpty ? "Unknown Location" : addressString
                self?.objectWillChange.send() // Notify the view that the address has changed
                DDLogInfo("Address found: \(self?.currentAddress ?? "No address found")") // Logging found address
            } else {
                self?.error = "No address found."
                self?.objectWillChange.send() // Notify the view about the error change
                DDLogError("No address found.") // Logging error when address is not found
            }
        }
    }
    
    // Check for location permissions
    func checkAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()  // Ask for permission
        case .denied, .restricted:
            error = "Location access denied. Please enable location access in Settings."
            objectWillChange.send() // Notify the view about the error change
            DDLogError("Location access denied.") // Logging denied access
        case .authorizedWhenInUse, .authorizedAlways:
            break  // Permission granted
        @unknown default:
            break
        }
    }

    // Open App Settings for location permissions
    func openAppSettings() {
        guard let appSettingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(appSettingsUrl) {
            UIApplication.shared.open(appSettingsUrl)
        }
    }
}
