//
//  KRTANGOSApp.swift
//  KRTANGOS
//
//  Korean vocabulary learning app
//

import SwiftUI
import CoreData

@main
struct KRTANGOSApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
