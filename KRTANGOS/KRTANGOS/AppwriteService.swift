//
//  AppwriteService.swift
//  KRTANGOS
//
//  Appwrite cloud database service
//

import Foundation
import Appwrite
import AppwriteModels

// Keep existing VocabularyData for backward compatibility
struct VocabularyData: Codable, Identifiable {
    let id: String
    let korean: String
    let japanese: String
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case korean
        case japanese
    }
}

// New SentenceData structure
struct SentenceData: Codable, Identifiable {
    let id: String
    let korean: String
    let japanese: String
    let source: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "$id"
        case korean
        case japanese
        case source
    }
}

class AppwriteService {
    private let client: Client
    private let databases: Databases
    
    init() {
        client = Client()
            .setEndpoint("https://cloud.appwrite.io/v1")
            .setProject("692bc656003484c795d8")
        
        databases = Databases(client)
    }
    
    // Existing vocabulary fetch function
    func fetchVocabularyFromCloud() async throws -> [VocabularyData] {
        print("🔍 Starting Appwrite vocabulary fetch...")
        
        do {
            let response = try await databases.listDocuments(
                databaseId: "692bc8d200345575c86e",
                collectionId: "vocabulary",
                queries: [
                    Query.limit(1000),
                    Query.orderAsc("korean")
                ]
            )
            
            print("📦 Received \(response.documents.count) vocabulary documents from Appwrite")
            
            var vocabularyItems: [VocabularyData] = []
            
            for (index, document) in response.documents.enumerated() {
                print("📄 Document \(index): \(document.data)")
                
                var korean: String = ""
                var japanese: String = ""
                
                if let k = document.data["korean"] as? String {
                    korean = k
                } else if let k = document.data["korean"] {
                    korean = "\(k)".trimmingCharacters(in: .whitespaces)
                }
                
                if let j = document.data["japanese"] as? String {
                    japanese = j
                } else if let j = document.data["japanese"] {
                    japanese = "\(j)".trimmingCharacters(in: .whitespaces)
                }
                
                korean = korean
                    .replacingOccurrences(of: "Optional(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                japanese = japanese
                    .replacingOccurrences(of: "Optional(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                guard !korean.isEmpty && !japanese.isEmpty else {
                    print("⚠️ Skipping document with empty fields")
                    continue
                }
                
                let vocab = VocabularyData(
                    id: document.id,
                    korean: korean,
                    japanese: japanese
                )
                
                vocabularyItems.append(vocab)
                print("✅ Parsed: \(korean) → \(japanese)")
            }
            
            print("✅ Successfully parsed \(vocabularyItems.count) vocabulary items")
            return vocabularyItems
            
        } catch {
            print("❌ Error fetching vocabulary from Appwrite: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    // New function to fetch sentences
    func fetchSentencesFromCloud() async throws -> [SentenceData] {
        print("🔍 Starting Appwrite sentences fetch...")
        
        do {
            let response = try await databases.listDocuments(
                databaseId: "692bc8d200345575c86e",
                collectionId: "sentences",
                queries: [
                    Query.limit(500),
                    Query.orderDesc("$createdAt") // Get most recent first
                ]
            )
            
            print("📦 Received \(response.documents.count) sentence documents from Appwrite")
            
            var sentenceItems: [SentenceData] = []
            
            for (index, document) in response.documents.enumerated() {
                print("📄 Sentence document \(index): \(document.data)")
                
                var korean: String = ""
                var japanese: String = ""
                var source: String? = nil
                
                // Extract korean field
                if let k = document.data["korean"] as? String {
                    korean = k
                } else if let k = document.data["korean"] {
                    korean = "\(k)".trimmingCharacters(in: .whitespaces)
                }
                
                // Extract japanese field
                if let j = document.data["japanese"] as? String {
                    japanese = j
                } else if let j = document.data["japanese"] {
                    japanese = "\(j)".trimmingCharacters(in: .whitespaces)
                }
                
                // Extract source field (optional)
                if let s = document.data["source"] as? String {
                    source = s
                }
                
                // Clean up any "Optional()" wrappers
                korean = korean
                    .replacingOccurrences(of: "Optional(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                japanese = japanese
                    .replacingOccurrences(of: "Optional(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                guard !korean.isEmpty && !japanese.isEmpty else {
                    print("⚠️ Skipping sentence with empty fields")
                    continue
                }
                
                let sentence = SentenceData(
                    id: document.id,
                    korean: korean,
                    japanese: japanese,
                    source: source
                )
                
                sentenceItems.append(sentence)
                print("✅ Parsed sentence: \(korean.prefix(50))...")
            }
            
            print("✅ Successfully parsed \(sentenceItems.count) sentence items")
            return sentenceItems
            
        } catch {
            print("❌ Error fetching sentences from Appwrite: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }
}
