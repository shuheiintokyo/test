//
//  SentenceItem+CoreDataProperties.swift
//  KRTANGOS
//
//  Core Data entity for storing Korean sentences
//

import Foundation
import CoreData

extension SentenceItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SentenceItem> {
        return NSFetchRequest<SentenceItem>(entityName: "SentenceItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var korean: String?
    @NSManaged public var japanese: String?
    @NSManaged public var source: String?
    @NSManaged public var createdAt: Date?
}

extension SentenceItem: Identifiable {
}
