//
//  testmapApp.swift
//  testmap
//
//  Created by Shuhei Kinugasa on 2025/10/15.
//

import SwiftUI
import CoreData

@main
struct testmapApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            GoldenGaiMapView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
