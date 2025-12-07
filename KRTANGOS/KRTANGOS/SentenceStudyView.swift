//
//  SentenceStudyView.swift
//  KRTANGOS
//
//  Study Korean sentences with tap-to-reveal Japanese translations
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
    
    @State private var currentIndex = 0
    @State private var isTranslationRevealed = false
    @State private var isLoading = false
    @State private var loadError: String?
    
    private let appwriteService = AppwriteService()
    
    var currentSentence: SentenceItem? {
        guard allSentences.indices.contains(currentIndex) else { return nil }
        return allSentences[currentIndex]
    }
    
    var progress: Double {
        guard !allSentences.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(allSentences.count)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if allSentences.isEmpty {
                    emptyStateView
                } else {
                    // Progress Section
                    VStack(spacing: 12) {
                        HStack {
                            Text("文章 \(currentIndex + 1) / \(allSentences.count)")
                                .font(.headline)
                            
                            Spacer()
                            
                            if let sentence = currentSentence, let source = sentence.source {
                                Text(source)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(6)
                            }
                        }
                        
                        ProgressView(value: progress)
                            .tint(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    
                    Spacer()
                    
                    if let sentence = currentSentence {
                        sentenceCards(for: sentence)
                    }
                    
                    Spacer()
                    
                    // Navigation Buttons
                    navigationButtons
                        .padding()
                }
            }
            .navigationTitle("韓国語の文章")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadSentencesFromCloud()
                        }
                    }) {
                        Label("更新", systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
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
    
    private func sentenceCards(for sentence: SentenceItem) -> some View {
        VStack(spacing: 32) {
            // Korean Sentence Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.blue)
                    Text("韓国語")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Text(sentence.korean ?? "")
                    .font(.system(size: 28, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Japanese Translation Card (Tap to Reveal)
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.orange)
                    Text("日本語訳")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if isTranslationRevealed {
                    Text(sentence.japanese ?? "")
                        .font(.system(size: 24, weight: .regular))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange.opacity(0.6))
                        
                        Text("タップして日本語訳を表示")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 150)
            .padding(24)
            .background(
                isTranslationRevealed
                    ? Color(.systemBackground)
                    : Color(.systemGray6)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isTranslationRevealed = true
                }
            }
        }
        .padding()
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            Button(action: previousSentence) {
                Label("前へ", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.bordered)
            .disabled(currentIndex == 0)
            
            Button(action: nextSentence) {
                Label("次へ", systemImage: "chevron.right")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(currentIndex >= allSentences.count - 1)
        }
    }
    
    private func nextSentence() {
        withAnimation {
            if currentIndex < allSentences.count - 1 {
                currentIndex += 1
                isTranslationRevealed = false
            }
        }
    }
    
    private func previousSentence() {
        withAnimation {
            if currentIndex > 0 {
                currentIndex -= 1
                isTranslationRevealed = false
            }
        }
    }
    
    private func loadSentencesFromCloud() async {
        isLoading = true
        loadError = nil
        
        do {
            print("📥 Fetching sentences from Appwrite...")
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
                    currentIndex = 0
                    isTranslationRevealed = false
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
