//
//  SentenceStudyView.swift
//  KRTANGOS
//
//  Study Korean sentences as a vertical list with tap-to-reveal translations
//

import Foundation
import SwiftUI
import CoreData

struct SentenceStudyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: SentenceItem.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SentenceItem.createdAt, ascending: false)]
    )
    private var allSentences: FetchedResults<SentenceItem>
    
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var expandedSentenceIds: Set<UUID> = []
    
    private let appwriteService = AppwriteService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with refresh button
                VStack(spacing: 12) {
                    HStack {
                        Text("韓国語の文章")
                            .font(.title2.bold())
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await loadSentencesFromCloud()
                            }
                        }) {
                            Image(systemName: isLoading ? "arrow.clockwise" : "arrow.clockwise")
                                .rotationEffect(isLoading ? .degrees(360) : .degrees(0))
                                .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                        }
                        .disabled(isLoading)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                
                // Sentences list
                if allSentences.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(allSentences) { sentence in
                                sentenceBlock(for: sentence)
                            }
                        }
                        .padding()
                    }
                }
            }
            .onAppear {
                if allSentences.isEmpty {
                    Task {
                        await loadSentencesFromCloud()
                    }
                }
            }
            .alert("エラー", isPresented: .constant(loadError != nil)) {
                Button("OK") {
                    loadError = nil
                }
            } message: {
                if let error = loadError {
                    Text(error)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("文章を読み込み中...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("文章がありません")
                    .font(.title2.bold())
                
                Text("上の更新ボタンを押して文章を取得してください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    Task {
                        await loadSentencesFromCloud()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("文章を取得")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func sentenceBlock(for sentence: SentenceItem) -> some View {
        let isExpanded = expandedSentenceIds.contains(sentence.id ?? UUID())
        
        return VStack(spacing: 0) {
            // Korean sentence (always visible)
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("韓国語")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let source = sentence.source {
                        Text(source)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                }
                
                Text(sentence.korean ?? "")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Japanese translation (shown when expanded)
            if isExpanded {
                Divider()
                    .padding(0)
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "flag.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("日本語訳")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    Text(sentence.japanese ?? "")
                        .font(.system(size: 16, weight: .regular))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if let id = sentence.id {
                    if expandedSentenceIds.contains(id) {
                        expandedSentenceIds.remove(id)
                    } else {
                        expandedSentenceIds.insert(id)
                    }
                }
            }
        }
    }
    
    private func loadSentencesFromCloud() async {
        isLoading = true
        loadError = nil
        
        do {
            print("🔥 Fetching sentences from Appwrite...")
            let sentences = try await appwriteService.fetchSentencesFromCloud()
            
            await MainActor.run {
                // Clear existing sentences
                for sentence in allSentences {
                    viewContext.delete(sentence)
                }
                
                // Add new sentences
                for sentenceData in sentences {
                    let newSentence = SentenceItem(context: viewContext)
                    newSentence.id = UUID()
                    newSentence.korean = sentenceData.korean
                    newSentence.japanese = sentenceData.japanese
                    newSentence.source = sentenceData.source
                    newSentence.createdAt = Date()
                }
                
                // Save context
                do {
                    try viewContext.save()
                    print("✅ Saved \(sentences.count) sentences to Core Data")
                } catch {
                    print("❌ Error saving sentences: \(error)")
                    loadError = "文章の保存に失敗しました"
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                print("❌ Error loading sentences: \(error)")
                loadError = "文章の取得に失敗しました: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

// Preview Provider
struct SentenceStudyView_Previews: PreviewProvider {
    static var previews: some View {
        SentenceStudyView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
