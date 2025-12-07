//
//  MainTabView.swift
//  KRTANGOS
//
//  Main tab container with sentence study and settings
//

import SwiftUI
import CoreData

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            SentenceStudyView()
                .tabItem {
                    Label("文章", systemImage: "doc.text")
                }
            
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
