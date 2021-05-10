//
//  Examples.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation

//final class ExempleCase1 {
//   var repository: AccessableRepository
//   
//   init(repository: AccessableRepository) {
//      self.repository = repository
//   }
//}

//final class ExampleCase2 {
//  var repository: Repository<Book>
//
//   init(repository: Repository<Book>) {
//      self.repository = repository
//   }
//}

final class ExampleCase3 {
  var repository: Repository<Book>

   init(repository: Repository<Book>) {
      self.repository = repository
   }
 
   func generateMock() -> [Book] {
      var books: [Book] = []
      for index in 0...20000 {
         books.append(Book(title: "MockBook\(index)",
                           isFavorite: false,
                           guid: "guid\(index)"))
      }
      return books
   }
   func startSaving(_ books: [Book]) {
      let startTime = CFAbsoluteTimeGetCurrent()
      ConsoleLog.logEvent(object: "ExempleCase3", method: "Saving start", "")
      repository.save(books) { result in
         let total = CFAbsoluteTimeGetCurrent() - startTime
         ConsoleLog.logEvent(object: "ExempleCase3", method: "Saving complete", "success: \(result.success != nil). Total time: \(total)")
      }
   }
}

