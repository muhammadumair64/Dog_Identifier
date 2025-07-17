import Foundation
import CocoaLumberjack

enum DogDataLoaderError: Error {
    case resourceNotFound
}

final class DogDataLoader {
    static func getDogsData() async throws -> [Dog] {
        DDLogVerbose("Reading dogs.json from bundle")

        guard let url = Bundle.main.url(forResource: "dogs", withExtension: "json") else {
            DDLogError("dogs.json file not found in bundle")
            throw DogDataLoaderError.resourceNotFound
        }

        let data = try await Task.detached(priority: .utility) {
            try Data(contentsOf: url)
        }.value

        DDLogVerbose("dogs.json size: \(data.count / 1024) KB")

        do {
            let dogs = try JSONDecoder().decode([Dog].self, from: data)
            DDLogInfo("Successfully parsed dogs.json with \(dogs.count) dogs")
            return dogs
        } catch {
            DDLogError("Failed to parse dogs.json: \(error.localizedDescription)")
            throw error
        }
    }
}
