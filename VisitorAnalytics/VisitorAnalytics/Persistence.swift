import CoreData

struct Persistence {
    static let shared = Persistence()

    static var preview: Persistence = {
        let result = Persistence(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews if needed
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "VisitorAnalytics")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // For now, we'll just print the error since we're primarily using our custom DataManager
                print("CoreData error: \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

// Note: We're keeping CoreData initialization for compatibility,
// but our app primarily uses DataManager with UserDefaults/Appwrite
