//
//  testApp.swift
//  test
//
//  Updated for Receipt OCR with Camera & Photo Library support
//

import SwiftUI
import CoreData

@main
struct testApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
