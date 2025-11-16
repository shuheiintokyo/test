import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager()
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Check In", systemImage: "person.badge.plus")
                }
                .environmentObject(dataManager)
            
            CurrentStatusView()
                .tabItem {
                    Label("Current", systemImage: "person.3.fill")
                }
                .environmentObject(dataManager)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .environmentObject(dataManager)
        }
        .onAppear {
            dataManager.loadActiveVisitors()
        }
    }
}

#Preview {
    ContentView()
}
