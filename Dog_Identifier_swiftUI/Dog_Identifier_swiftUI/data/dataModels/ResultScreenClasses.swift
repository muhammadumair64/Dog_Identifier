import SwiftUI

class DogResponse {
    var name: String
    var details: String
    var lifeSpan: String
    var diet: [DietItem]
    var biteForce: String
    var impactOnHumans: String
    var countries: [String]
    var goodHabits: [DogHabit]
    var badHabits: [DogHabit]
    var characteristics: DogCharacteristics
    var classification: Classification
    var speciesName: String
    
    init(name: String,
         details: String,
         lifeSpan: String,
         diet: [DietItem],
         biteForce: String,
         impactOnHumans: String,
         countries: [String],
         goodHabits: [DogHabit],
         badHabits: [DogHabit],
         characteristics: DogCharacteristics,
         classification: Classification,
         speciesName: String) {
        self.name = name
        self.details = details
        self.lifeSpan = lifeSpan
        self.diet = diet
        self.biteForce = biteForce
        self.impactOnHumans = impactOnHumans
        self.countries = countries
        self.goodHabits = goodHabits
        self.badHabits = badHabits
        self.characteristics = characteristics
        self.classification = classification
        self.speciesName = speciesName
    }
}
class DogHabit: Identifiable {
    let id = UUID()
    var title: String
    var description: String
    
    init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}

class DogCharacteristics {
    var size: String
    var colors: [String]
    var colorCodes: [String]
    
    init(size: String, colors: [String], colorCodes: [String]) {
        self.size = size
        self.colors = colors
        self.colorCodes = colorCodes
    }
}

// Reusable classification
class Classification {
    var genus: String
    var family: String
    var order: String
    
    init(genus: String, family: String, order: String) {
        self.genus = genus
        self.family = family
        self.order = order
    }
}

// Reusable diet item
struct DietItem: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
}

struct ValueWithColor: Identifiable {
    let id = UUID()
    let value: String      // e.g., "White"
    let color: String      // e.g., "#FFFFFF"
}
