import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Dog_Identifier_swiftUI")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error: \(error)")
            }
        }
    }

    // Main context (for UI-related operations)
    var context: NSManagedObjectContext {
        return container.viewContext
    }

    // Background context (for background operations)
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    // Save context if there are changes
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
