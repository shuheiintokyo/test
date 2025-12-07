//
//  MainTabView.swift
//  KRTANGOS
//
//  Main tab container with vocabulary list, sentence study, and settings
//

import SwiftUI
import CoreData

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        TabView {
            VocabularyListViewWithSync()
                .tabItem {
                    Label("リスト", systemImage: "list.bullet")
                }
            
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

// MARK: - Vocabulary List View with Cloud Sync
struct VocabularyListViewWithSync: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: VocabularyItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \VocabularyItem.korean, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<VocabularyItem>
    
    @State private var appwriteService = AppwriteService()
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var searchText = ""
    @State private var lastSyncDate: Date?
    
    var filteredItems: [VocabularyItem] {
        if searchText.isEmpty {
            return Array(items)
        } else {
            return items.filter { item in
                (item.korean?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.japanese?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var todayAdded: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return items.filter { item in
            guard let createdAt = item.createdAt else { return false }
            return calendar.isDate(createdAt, inSameDayAs: today)
        }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Card
                statsCard
                    .padding()
                
                // Cloud sync button
                HStack {
                    Button(action: updateDataFromCloud) {
                        HStack {
                            Image(systemName: isUpdating ? "arrow.clockwise" : "icloud.and.arrow.down")
                                .rotationEffect(isUpdating ? .degrees(360) : .degrees(0))
                                .animation(isUpdating ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isUpdating)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("クラウドから更新")
                                    .font(.system(size: 15, weight: .semibold))
                                
                                if let lastSync = lastSyncDate {
                                    Text("最終: \(formatDate(lastSync))")
                                        .font(.caption2)
                                        .opacity(0.8)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isUpdating)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                // Vocabulary list
                if items.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            VocabularyRow(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("韓単語帳")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .searchable(text: $searchText, prompt: "単語を検索")
            .alert("更新結果", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
            }
        }
    }
    
    private var statsCard: some View {
        HStack(spacing: 20) {
            StatItem(icon: "book.fill", value: "\(items.count)", label: "全単語数", color: .orange)
            
            Divider()
                .frame(height: 40)
            
            StatItem(icon: "chart.line.uptrend.xyaxis", value: "\(todayAdded)", label: "今日追加", color: .orange)
            
            Divider()
                .frame(height: 40)
            
            StatItem(icon: "star.fill", value: "\(items.count)", label: "学習中", color: .orange)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.5))
            
            Text("語呂がありません")
                .font(.title2.bold())
            
            Text("「クラウドから更新」をタップして\n単語を読み込んでください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting item: \(error)")
            }
        }
    }
    
    private func updateDataFromCloud() {
        isUpdating = true
        
        Task {
            do {
                let vocabularyItems = try await appwriteService.fetchVocabularyFromCloud()
                
                await MainActor.run {
                    var newCount = 0
                    var updatedCount = 0
                    
                    for vocabData in vocabularyItems {
                        let fetchRequest: NSFetchRequest<VocabularyItem> = VocabularyItem.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "korean == %@", vocabData.korean)
                        
                        do {
                            let results = try viewContext.fetch(fetchRequest)
                            
                            if let existingItem = results.first {
                                existingItem.japanese = vocabData.japanese
                                updatedCount += 1
                            } else {
                                let newItem = VocabularyItem(context: viewContext)
                                newItem.id = UUID()
                                newItem.korean = vocabData.korean
                                newItem.japanese = vocabData.japanese
                                newItem.createdAt = Date()
                                newCount += 1
                            }
                        } catch {
                            print("Error checking existing item: \(error)")
                        }
                    }
                    
                    do {
                        if viewContext.hasChanges {
                            try viewContext.save()
                        }
                        lastSyncDate = Date()
                        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
                        alertMessage = "更新完了！\n新規: \(newCount)件\n更新: \(updatedCount)件"
                    } catch {
                        alertMessage = "保存エラー: \(error.localizedDescription)"
                    }
                    
                    isUpdating = false
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "クラウドからのデータ取得に失敗しました: \(error.localizedDescription)"
                    isUpdating = false
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2.bold())
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vocabulary Row
struct VocabularyRow: View {
    let item: VocabularyItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Korean word
            Text(item.korean ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Arrow separator
            Text("→")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
            
            // Japanese translation
            Text(item.japanese ?? "")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
