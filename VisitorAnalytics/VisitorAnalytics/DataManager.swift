import Foundation
import SwiftUI
import CoreData
import Combine

// Hybrid DataManager that uses CoreData locally and Appwrite for cloud sync
class DataManager: ObservableObject {
    @Published var activeVisitors: [Visitor]
    @Published var allVisitors: [Visitor]
    @Published var todayVisitorCount: Int
    @Published var singleCount: Int
    @Published var pairCount: Int
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    
    // Appwrite integration (will be enabled when import is fixed)
    private let appwriteService = AppwriteService.shared
    private let useAppwrite = false
    
    // CoreData context
    private let viewContext: NSManagedObjectContext?
    
    // Local storage with UserDefaults as fallback
    private let userDefaults = UserDefaults.standard
    private let activeVisitorsKey = "activeVisitors"
    private let allVisitorsKey = "allVisitors"
    
    init(context: NSManagedObjectContext? = nil) {
        // Initialize all @Published properties first
        self.activeVisitors = []
        self.allVisitors = []
        self.todayVisitorCount = 0
        self.singleCount = 0
        self.pairCount = 0
        self.isLoading = false
        self.errorMessage = nil
        
        // Then set other properties
        self.viewContext = context
        
        // Load data after initialization
        loadActiveVisitors()
        loadAllVisitors()
        loadTodayStats()
    }
    
    // MARK: - Data Operations
    
    func saveVisitor(_ visitor: Visitor) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            if useAppwrite {
                try await appwriteService.createVisitor(visitor)
            }
            
            await MainActor.run {
                activeVisitors.append(visitor)
                allVisitors.append(visitor)
                saveToLocal()
                
                if let context = viewContext {
                    saveToCoreDat(visitor: visitor, context: context)
                }
                
                loadTodayStats()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                activeVisitors.append(visitor)
                allVisitors.append(visitor)
                saveToLocal()
                
                if let context = viewContext {
                    saveToCoreDat(visitor: visitor, context: context)
                }
                
                loadTodayStats()
                errorMessage = "Cloud save failed, saved locally: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func updateVisitor(_ visitor: Visitor) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            if useAppwrite {
                try await appwriteService.updateVisitor(visitor)
            }
            
            await MainActor.run {
                if let index = activeVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    activeVisitors[index] = visitor
                }
                
                if let index = allVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    allVisitors[index] = visitor
                }
                
                saveToLocal()
                
                if let context = viewContext {
                    updateInCoreData(visitor: visitor, context: context)
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                if let index = activeVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    activeVisitors[index] = visitor
                }
                if let index = allVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    allVisitors[index] = visitor
                }
                
                saveToLocal()
                
                if let context = viewContext {
                    updateInCoreData(visitor: visitor, context: context)
                }
                
                errorMessage = "Cloud update failed, updated locally"
                isLoading = false
            }
        }
    }
    
    func markVisitorAsLeft(_ visitor: Visitor) async {
        var updatedVisitor = visitor
        updatedVisitor.exitTime = Date()
        updatedVisitor.isActive = false
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            if useAppwrite {
                try await appwriteService.updateVisitor(updatedVisitor)
            }
            
            await MainActor.run {
                activeVisitors.removeAll { $0.id == visitor.id }
                
                if let index = allVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    allVisitors[index] = updatedVisitor
                }
                
                saveToLocal()
                
                if let context = viewContext {
                    updateInCoreData(visitor: updatedVisitor, context: context)
                }
                
                loadTodayStats()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                activeVisitors.removeAll { $0.id == visitor.id }
                
                if let index = allVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    allVisitors[index] = updatedVisitor
                }
                
                saveToLocal()
                
                if let context = viewContext {
                    updateInCoreData(visitor: updatedVisitor, context: context)
                }
                
                loadTodayStats()
                errorMessage = "Cloud update failed, updated locally"
                isLoading = false
            }
        }
    }
    
    // MARK: - Local Storage (UserDefaults)
    
    func loadActiveVisitors() {
        if let data = userDefaults.data(forKey: activeVisitorsKey),
           let decoded = try? JSONDecoder().decode([Visitor].self, from: data) {
            activeVisitors = decoded.filter { $0.isActive }
        }
    }
    
    func loadAllVisitors() {
        if let data = userDefaults.data(forKey: allVisitorsKey),
           let decoded = try? JSONDecoder().decode([Visitor].self, from: data) {
            allVisitors = decoded
        }
    }
    
    func loadTodayStats() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        todayVisitorCount = allVisitors.filter { visitor in
            calendar.startOfDay(for: visitor.entryTime) == today
        }.count
        
        singleCount = allVisitors.filter { $0.groupType == .single }.count
        pairCount = allVisitors.filter { $0.groupType == .pair }.count
    }
    
    private func saveToLocal() {
        if let encoded = try? JSONEncoder().encode(activeVisitors) {
            userDefaults.set(encoded, forKey: activeVisitorsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(allVisitors) {
            userDefaults.set(encoded, forKey: allVisitorsKey)
        }
    }
    
    // MARK: - CoreData Operations (Optional)
    
    private func saveToCoreDat(visitor: Visitor, context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error)")
        }
    }
    
    private func updateInCoreData(visitor: Visitor, context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("CoreData update error: \(error)")
        }
    }
    
    // MARK: - Sync with Appwrite (when available)
    
    func syncWithCloud() async {
        guard useAppwrite else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let cloudVisitors = try await appwriteService.getAllVisitors()
            let cloudActive = try await appwriteService.getActiveVisitors()
            
            await MainActor.run {
                if !cloudVisitors.isEmpty {
                    allVisitors = cloudVisitors
                }
                if !cloudActive.isEmpty {
                    activeVisitors = cloudActive
                }
                
                saveToLocal()
                loadTodayStats()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Cloud sync failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Clear Data (for testing)
    
    func clearAllData() {
        activeVisitors.removeAll()
        allVisitors.removeAll()
        saveToLocal()
        loadTodayStats()
    }
}
