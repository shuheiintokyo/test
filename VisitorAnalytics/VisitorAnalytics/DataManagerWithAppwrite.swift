import Foundation
import SwiftUI
import Combine

class DataManagerWithAppwrite: ObservableObject {
    @Published var activeVisitors: [Visitor]
    @Published var allVisitors: [Visitor]
    @Published var todayVisitorCount: Int
    @Published var singleCount: Int
    @Published var pairCount: Int
    @Published var isLoading: Bool
    @Published var errorMessage: String?
    
    private let appwriteService = AppwriteService.shared
    private let useAppwrite = false
    private let userDefaults = UserDefaults.standard
    private let activeVisitorsKey = "activeVisitors"
    private let allVisitorsKey = "allVisitors"
    
    init() {
        self.activeVisitors = []
        self.allVisitors = []
        self.todayVisitorCount = 0
        self.singleCount = 0
        self.pairCount = 0
        self.isLoading = false
        self.errorMessage = nil
        
        Task {
            await loadData()
        }
    }
    
    func saveVisitor(_ visitor: Visitor) async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            if useAppwrite {
                _ = try await appwriteService.createVisitor(visitor)
            }
            
            await MainActor.run {
                activeVisitors.append(visitor)
                allVisitors.append(visitor)
                
                if !useAppwrite {
                    saveToLocal()
                }
                
                loadTodayStats()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save visitor: \(error.localizedDescription)"
                isLoading = false
            }
            throw error
        }
    }
    
    func updateVisitor(_ visitor: Visitor) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            if useAppwrite {
                _ = try await appwriteService.updateVisitor(visitor)
            }
            
            await MainActor.run {
                if let index = activeVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    activeVisitors[index] = visitor
                }
                
                if let index = allVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    allVisitors[index] = visitor
                }
                
                if !useAppwrite {
                    saveToLocal()
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to update visitor: \(error.localizedDescription)"
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
                _ = try await appwriteService.updateVisitor(updatedVisitor)
            }
            
            await MainActor.run {
                activeVisitors.removeAll { $0.id == visitor.id }
                
                if let index = allVisitors.firstIndex(where: { $0.id == visitor.id }) {
                    allVisitors[index] = updatedVisitor
                }
                
                if !useAppwrite {
                    saveToLocal()
                }
                
                loadTodayStats()
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to mark visitor as left: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func loadData() async {
        if useAppwrite {
            await loadFromAppwrite()
        } else {
            await MainActor.run {
                loadFromLocal()
            }
        }
    }
    
    private func loadFromAppwrite() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let active = try await appwriteService.getActiveVisitors()
            let all = try await appwriteService.getAllVisitors()
            
            await MainActor.run {
                self.activeVisitors = active
                self.allVisitors = all
                self.loadTodayStats()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load data: \(error.localizedDescription)"
                isLoading = false
                loadFromLocal()
            }
        }
    }
    
    private func loadFromLocal() {
        loadActiveVisitors()
        loadAllVisitors()
        loadTodayStats()
    }
    
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
    
    func clearAllData() {
        activeVisitors.removeAll()
        allVisitors.removeAll()
        saveToLocal()
        loadTodayStats()
    }
}

