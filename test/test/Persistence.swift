//
//  Persistence.swift
//  test
//
//  Created by Shuhei Kinugasa on 2025/11/01.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "test")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CoreData error: \(error)")
            }
        }
    }
}
