//
//  VocabularyItem+CoreDataProperties.swift
//  KRTANGOS
//
//  Core Data entity for storing Korean vocabulary
//

import Foundation
import CoreData

extension VocabularyItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<VocabularyItem> {
        return NSFetchRequest<VocabularyItem>(entityName: "VocabularyItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var korean: String?
    @NSManaged public var japanese: String?
    @NSManaged public var createdAt: Date?
}

extension VocabularyItem: Identifiable {
}
