//
//  BookEntityMapper.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 09.05.2021.
//

import Foundation
import CoreData

final class BookEntityMapper: DBEntityMapper<Book, BookEntity> {
   override func convert(_ entity: BookEntity) -> Book? {
      guard let title = entity.title, let guid = entity.guid else { return nil }
      return Book(title: title,
          description: entity.bookDescription,
          isFavorite: entity.isFavorite,
          guid: guid)
   }
   override func update(_ entity: BookEntity, by model: Book) {
      entity.title = model.title
      entity.bookDescription = model.description
      entity.guid = model.guid
      entity.isFavorite = model.isFavorite
      
      //MARK: - Place for adding relationShips
//      guard let context = entity.managedObjectContext else { return }
    
   }
   
   override func entityAccessorKey(_ object: Book) -> String {
      object.guid
   }
   override func entityAccessorKey(_ entity: BookEntity) -> String {
      entity.guid ?? ""
   }
}
