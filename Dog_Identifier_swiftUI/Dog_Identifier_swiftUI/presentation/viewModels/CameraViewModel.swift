//
//  CameraViewModel.swift
//  Insect-detector-ios
//
//  Created by Mac Mini on 19/12/2024.
//


import SwiftUI
import AVFoundation
import GoogleGenerativeAI
import Foundation
import CocoaLumberjack

class CameraViewModel: ObservableObject {
   
//    AIzaSyAFgJCBsh92JSpQczp4jZM3orgLQtSaYcc   Same Key from Butterfly IOS
    let model = GenerativeModel(name: "gemini-1.5-flash-8b", apiKey: "AIzaSyAFgJCBsh92JSpQczp4jZM3orgLQtSaYcc")
    
    // This property will be shared across all views
    @Published var capturedImage: UIImage? = nil
    @Published var croppedImage: UIImage? = nil
    @Published var isFlashOn: Bool = false
    @Published var cameraSession: AVCaptureSession?
    @Published var response:LocalizedStringKey = ""
    @Published var dogResponse: DogResponse?
    @Published var responseReceived = false
    @Published var isScanningFailed = false
    
    @Published var images: [PixabayImage] = []
    
    @Published var showAlert = false
    
     var task: Task<Void, Never>?

    let prefix = """
    Identify whether the input is a dog or not.

    If it is not a dog, respond exactly with:
    no dog found

    If it is a dog, provide the following fields in this exact format without extra spaces or newlines , do not add promt text in respone :

    -1: Name (Only name)
    -2: [Details about this dog in 10 lines. Full sentences. Max 1-2 sentences per line.]
    -3: [Life span in years format. Use: min-max (only numbers, no text)]
    -4:
    [List of what it eats. One item per line. Keep this format.]
    -5: [Bite force in PSI (number only)]
    Impact on Humans
    [List the effects of this dog’s bite on humans in 4-5 bullet points.]
    -6:
    [List of top 6 countries where this dog is found. One country per line.]
    -7: 
    [List of Good habits using numbered bullet points. Format: number. Title: Description]
    -8: 
    [List of Bad habits using numbered bullet points. Format: number. Title: Description]
    -9: Size: [Adult size in cm (number only with cm)]
    -10: Colors: [List of color names separated by commas]
    [Comma-separated hex color codes, matching the above colors. No label here.]
    -11: Genus: [Genus], Family: [Family], Order: [Order]
    -12: [Species name only]
    """



    
//    var prefix = "Identify if it is an dog or not. If not, provide the result as no dog found. If it is an  dog, provide (don't place extra spaces and extra line breaks):" +
//            " -1: Name (Only name)" +
//            " -2: Detail about this particular dog (in 10 lines)" +
//            " -3: Life span only assume minimum to maximum in numbers of days only don't give me years or months, don't tell any extra thing, place - between minimum to maximum days" +
//            " -4: What it eats in form of list" +
//            " -5: Give me bite force in PSI(Only value), Tell me the Impact of bite on the human of this particular dog with heading of Impact on Humans" +
//            " -6: Give me countries name list where it found (just give top 6 countries)" +
//            " -7: Give me Good habits of this dog with title(use number bullets) and description" +
//            " -8: Give me Bad habits of this dog with title(use number bullets) and description" +
//            " -9: Characteristics (Adult Size only in number don't explain(male cm, female cm) with title size, Colors (only list of name of colors) with title colors, Colors code of that colors (give me similar color code if natural organic variations are unable to find) don't add any title)" +
//            " -10: Classifications (Genus, Family, Order) -11: Name of Species(just only name)"
    
    
//    var prefix = "Identify if it is an dog or not. If not, provide the result as no dog found. If it is an dog, provide (don't place extra spaces and extra line breaks):" +
//    " -1: Name (Only name)" +
//    " -2: Detail about this particular dog (in 10 lines)" +
//    " -3: Life span only assume minimum to maximum in numbers of days only don't give me years or months, don't tell any extra thing, place - between minimum to maximum days" +
//    " -4: What it eats in form of list" +
//    " -5: How it grows tell me process type name(place : after name) define this process type shortly and all stages in points with title and short description" +
//    " -6: Give me countries name list where it found (just give top 6 countries)" +
//    " -7: What kind of habitat it found" +
//    " -8: Does it venomous or not and what kind of venom does it have and if it bites what will happened to human body" +
//    " -9: Characteristics (Adult Size only in number don't explain(male mm, female mm) with title size. "  +
//    " -10: Colors (only list of name of colors) with title colors, Colors code of that colors (give me similar color code if natural organic variations are unable to find) with title Colors code both in same line" +
//    " -11: Classifications (Genus, Family, Order)"


    // You can add any other camera-related data or methods here
    
    func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            print("Flashlight not available")
            return
        }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flashlight: \(error.localizedDescription)")
        }
    }

    func generateResponse(with image: UIImage?) {
        // Cancel any previously running task before starting a new one
        cancelTask()

        // Perform the content generation in a background task
        task = Task {
            do {
                guard let image = image else { throw NSError(domain: "Invalid Image", code: -1, userInfo: nil) }
                
                // Check if the task is canceled before starting
                if Task.isCancelled { return }

                // Await the async call for content generation
                let result = try await self.model.generateContent(self.prefix, image)
                
                // Check if the task was canceled after awaiting
                if Task.isCancelled { return }

                // Update UI on the main thread
                await MainActor.run {
                    // Parse the result into structured data
                    self.dogResponse = self.parseResponse(result.text ?? "")
                    
                    // Print the parsed insect response
                    print("dog Response: \(result.text ?? "")")
                    if self.dogResponse?.name.isEmpty == true {
                        self.showAlert = true
                    } else {
                        self.responseReceived = true
                        if(dogResponse?.name != ""){
                            print("INSECT NAME IS \(dogResponse?.name ?? "")")
                            fetchInsect(dogResponse?.name ?? "")
                        }
                    }
                    self.response = LocalizedStringKey(result.text ?? "No response found")
                }
            } catch {
                // Handle error on the main thread if something goes wrong
                await MainActor.run {
                    self.showAlert = true
                    self.response = "Something went wrong! \n\(error.localizedDescription)"
                }
            }
        }
    }

    func cancelTask() {
        // Cancel the current task if it exists
        task?.cancel()
        task = nil
    }

    func parseResponse(_ text: String) -> DogResponse {
        var name = ""
        var details = ""
        var lifeSpan = ""
        var diet: [DietItem] = []
        var biteForce = ""
        var impactOnHumans = ""
        var countries: [String] = []
        var goodHabits: [DogHabit] = []
        var badHabits: [DogHabit] = []
        var characteristics = DogCharacteristics(size: "", colors: [], colorCodes: [])
        var classification = Classification(genus: "", family: "", order: "")
        var speciesName = ""

        let lines = text.components(separatedBy: "\n")

        var readingDiet = false
        var readingImpact = false
        var readingCountries = false
        var readingGoodHabits = false
        var readingBadHabits = false
        var readingColors = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            switch true {
            case trimmedLine.hasPrefix("-1:"):
                name = trimmedLine.replacingOccurrences(of: "-1:", with: "").trimmingCharacters(in: .whitespaces)
                DDLogInfo("Parsed name: \(name)")
            case trimmedLine.hasPrefix("-2:"):
                details = trimmedLine.replacingOccurrences(of: "-2:", with: "").trimmingCharacters(in: .whitespaces)
            case trimmedLine.hasPrefix("-3:"):
                lifeSpan = trimmedLine.replacingOccurrences(of: "-3:", with: "").trimmingCharacters(in: .whitespaces)
            case trimmedLine.hasPrefix("-4:"):
                readingDiet = true
            case trimmedLine.hasPrefix("-5:"):
                biteForce = trimmedLine.replacingOccurrences(of: "-5:", with: "").trimmingCharacters(in: .whitespaces)
                readingDiet = false
                readingImpact = true
            case trimmedLine == "Impact on Humans":
                continue
            case trimmedLine.hasPrefix("-6:"):
                readingImpact = false
                readingCountries = true
            case trimmedLine.hasPrefix("-7:"):
                readingCountries = false
                readingGoodHabits = true
            case trimmedLine.hasPrefix("-8:"):
                readingGoodHabits = false
                readingBadHabits = true
            case trimmedLine.hasPrefix("-9:"):
                readingBadHabits = false
                characteristics.size = trimmedLine.replacingOccurrences(of: "-9: Size:", with: "").trimmingCharacters(in: .whitespaces)
                DDLogInfo("Parsed size: \(characteristics.size)")
            case trimmedLine.hasPrefix("-10:"):
                readingColors = true
                if trimmedLine.contains("Colors:") {
                    let colorNames = trimmedLine.replacingOccurrences(of: "-10: Colors:", with: "").trimmingCharacters(in: .whitespaces)
                    characteristics.colors = colorNames.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    DDLogInfo("Parsed colors: \(characteristics.colors)")
                }
            case trimmedLine.hasPrefix("-11:"):
                readingColors = false
                let info = trimmedLine.replacingOccurrences(of: "-11:", with: "").trimmingCharacters(in: .whitespaces)
                let components = info.components(separatedBy: ",")
                for item in components {
                    if item.contains("Genus:") {
                        classification.genus = item.replacingOccurrences(of: "Genus:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if item.contains("Family:") {
                        classification.family = item.replacingOccurrences(of: "Family:", with: "").trimmingCharacters(in: .whitespaces)
                    } else if item.contains("Order:") {
                        classification.order = item.replacingOccurrences(of: "Order:", with: "").trimmingCharacters(in: .whitespaces)
                    }
                }
            case trimmedLine.hasPrefix("-12:"):
                speciesName = trimmedLine.replacingOccurrences(of: "-12:", with: "").trimmingCharacters(in: .whitespaces)
            default:
                if readingDiet && !trimmedLine.starts(with: "-") && !trimmedLine.isEmpty {
                    diet.append(DietItem(text: trimmedLine, color: .gray))
                } else if readingImpact && !trimmedLine.starts(with: "-") && !trimmedLine.isEmpty {
                    impactOnHumans += (impactOnHumans.isEmpty ? "" : " ") + trimmedLine
                } else if readingCountries && !trimmedLine.isEmpty {
                    countries.append(trimmedLine)
                } else if readingGoodHabits || readingBadHabits {
                    let pattern = #"^\d+\.\s*(.+?):\s*(.+)"#
                    let regex = try! NSRegularExpression(pattern: pattern)
                    let nsString = trimmedLine as NSString
                    if let match = regex.firstMatch(in: trimmedLine, range: NSRange(location: 0, length: nsString.length)) {
                        let title = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                        let description = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                        let habit = DogHabit(title: title, description: description)
                        if readingGoodHabits {
                            goodHabits.append(habit)
                        } else {
                            badHabits.append(habit)
                        }
                    }
                } else if readingColors && trimmedLine.contains("#") {
                    characteristics.colorCodes = trimmedLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    DDLogInfo("Parsed color codes: \(characteristics.colorCodes)")
                }
            }
        }

        return DogResponse(
            name: name,
            details: details,
            lifeSpan: lifeSpan,
            diet: diet,
            biteForce: biteForce,
            impactOnHumans: impactOnHumans,
            countries: countries,
            goodHabits: goodHabits,
            badHabits: badHabits,
            characteristics: characteristics,
            classification: classification,
            speciesName: speciesName
        )
    }





    
    func fetchInsect(_ name: String) {
        PixabayNetworkManager.shared.searchImages(query: name, category: "Insect") { [weak self] result in
            switch result {
            case .success(let images):
                // Save the fetched images to the list
                self?.images = images
                
                // Log the image URLs (optional)
                for image in images {
                    print("Image URL: \(image.largeImageURL)")
                }
                
                // Notify UI or further process the data here
                DispatchQueue.main.async {
                    // Add your UI update code if needed
                }
            case .failure(let error):
                print("Error: \(error.rawValue)")
            }
        }
    }
}

