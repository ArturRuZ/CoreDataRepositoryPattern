//
//  DBContextProvider.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 09.05.2021.
//

import Foundation
import CoreData

final class DBContextProvider {
   //1
   private lazy var persistentContainer: NSPersistentContainer = {
      let container = NSPersistentContainer(name: "DataStorageModel")
     
      container.loadPersistentStores(completionHandler: { (_, error) in
         if let error = error as NSError? {
            fatalError("Unresolved error \(error),\(error.userInfo)")
         }
         container.viewContext.automaticallyMergesChangesFromParent = true
      })
      return container
   }()
   //2
   private lazy var mainContext = persistentContainer.viewContext
}

//3
//MARK:- DBContextProviding implementation
extension DBContextProvider: DBContextProviding {
   func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
      persistentContainer.performBackgroundTask(block)
   }
   func mainQueueContext() -> NSManagedObjectContext {
      self.mainContext
   }
}
