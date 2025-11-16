//
//  testApp.swift
//  test
//
//  Created by Shuhei Kinugasa on 2025/11/01.
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
