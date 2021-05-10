//
//  Models.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation

class Book {
   var title: String
   var description: String?
   var isFavorite: Bool
   var guid: String
   
   init(title: String, description: String? = nil, isFavorite: Bool, guid: String) {
      self.title = title
      self.description = description
      self.isFavorite = isFavorite
      self.guid = guid
   }
}

