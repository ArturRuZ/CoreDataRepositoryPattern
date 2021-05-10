//
//  BookEntity+CoreDataProperties.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 10.05.2021.
//
//

import Foundation
import CoreData


extension BookEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookEntity> {
        return NSFetchRequest<BookEntity>(entityName: "BookEntity")
    }

    @NSManaged public var bookDescription: String?
    @NSManaged public var guid: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var title: String?

}
