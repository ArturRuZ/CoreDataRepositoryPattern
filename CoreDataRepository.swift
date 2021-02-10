//
//  CoreDataRepository.swift
//
//  Created by Artur Ruzhnikov on 09.02.2021.
//  Copyright © 2021. All rights reserved.
//


// TEMPLATE OF USAGE
/*
  class TestRepository: Repository<DBRepoRawData, DBRepoObjectModel> {

  override var actualData: Observable<[DBRepoObjectModel]>? {
     return nil
  }
  
  override func save(_ objects: [DBRepoObjectModel], completion: @escaping ((Result<Void>) -> Void)) {
  }
  override func save(_ rawData: [DBRepoRawData], completion: @escaping ((Result<Void>) -> Void)) {
  }
  override func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[DBRepoObjectModel]>) -> Void))
  {
  }
  override func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
  }
  }
 */


import Foundation
import CoreData

protocol AccessableRepository {
   associatedtype RawData: Codable
   associatedtype ObjectModel
   
   var actualData: Observable<[ObjectModel]>? {get}
   
   func save(_ rawData: [RawData], completion: @escaping ((Result<Void>) -> Void))
   func save(_ objects: [ObjectModel], completion: @escaping ((Result<Void>) -> Void))
   func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[ObjectModel]>) -> Void))
}

protocol EntityConvertable {
   func updateSelfFrom(schema: Codable)
   func transformSelfTo<T>(expectedType: T.Type) -> T?
}

protocol DBContextProviding {
   func mainQueueContext() -> NSManagedObjectContext
   func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
}
protocol RepositorySearchRequest {
   /* NSPredicate = nil,  apply for all records
    for deletion sortDescriptor is not Used
    */
   var predicate: NSPredicate? {get}
   var sortDescriptors: [NSSortDescriptor] {get}
}

enum RepositoryErrors: Error {
   case entityConvertableMissing
}
//extension RepositoryErrors: LocalizedError {
//
//}

//MARK: The way of fixing protocol error for generic types
class Repository<RepoRawData: Codable, RepoObjectModel>: AccessableRepository {
   typealias RawData = RepoRawData
   typealias ObjectModel = RepoObjectModel
   
   var actualData: Observable<[RepoObjectModel]>? { nil }
   
   func save(_ rawData: [RepoRawData], completion: @escaping ((Result<Void>) -> Void)) {}
   func save(_ objects: [RepoObjectModel], completion: @escaping ((Result<Void>) -> Void)) {}
   func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {}
   func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[RepoObjectModel]>) -> Void)) {}
}

//MARK: Repository implementation for CoreData usage
final class DBRepository<DBRepoRawData: Codable, DBRepoObjectModel, DBRepoGettingFilter>: Repository<DBRepoRawData, DBRepoObjectModel> {
   
   private let associatedEntity: String
   private let contextSource: DBContextProviding
   
   private func saveIn(context: NSManagedObjectContext, mergePolicy: Any = NSMergeByPropertyObjectTrumpMergePolicy, completion: ((Result<Void>) -> Void)? = nil) {
      context.mergePolicy = mergePolicy
      switch context.hasChanges {
      case true:
         do {
            try context.save()
         } catch {
            ConsoleLog.logEvent(object: "DBRepository", method: "saveIn", "Error: \(error)")
            completion?(Result.error(error))
         }
         ConsoleLog.logEvent(object: "DBRepository", method: "saveIn", "Saving Complete")
         completion?(Result(value: ()))
      case false:
         ConsoleLog.logEvent(object: "DBRepository", method: "saveIn", "No changes in context")
         completion?(Result(error: ErrorsList.noChangesInBase))
      }
      
   }
   
   private func configureActualDataUpdating(_ request: RepositorySearchRequest) {
      
   }
   
   init(associatedEntity: String, contextSource: DBContextProviding, autoUpdateSearchRequest: RepositorySearchRequest?) {
      self.associatedEntity = associatedEntity
      self.contextSource = contextSource
      super.init()
      
      guard let request = autoUpdateSearchRequest else { return }
      configureActualDataUpdating(request)
   }
   
   //MARK: - Overriding default Repository implementation
   override var actualData: Observable<[DBRepoObjectModel]>? {
      return nil
   }
   
   override func save(_ objects: [DBRepoObjectModel], completion: @escaping ((Result<Void>) -> Void)) {
      
   }
   override func save(_ rawData: [DBRepoRawData], completion: @escaping ((Result<Void>) -> Void)) {
      contextSource.performBackgroundTask() { context in
         // TO DO - Check case when CoreData not update someValues
         guard let _ = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntity, into: context) as? EntityConvertable else { return completion(Result(error: RepositoryErrors.entityConvertableMissing)) }
         
         rawData.forEach({
            let entity = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntity, into: context) as? EntityConvertable
            entity?.updateSelfFrom(schema: $0)
         })
         self.saveIn(context: context, completion: completion)
      }
   }
   override func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[DBRepoObjectModel]>) -> Void)) {
      var objects: [DBRepoObjectModel] = []
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntity)
      fetchRequest.predicate = search.predicate
      fetchRequest.sortDescriptors = search.sortDescriptors
      contextSource.performBackgroundTask() { context in
         do {
            let rawData = try context.fetch(fetchRequest)
            guard let results = rawData as? [EntityConvertable] else { return }
            
            results.forEach({
               guard let object = $0.transformSelfTo(expectedType: DBRepoObjectModel.self) else {return completion(Result(error: RepositoryErrors.entityConvertableMissing))}
               objects.append(object)
            })
            return completion(Result(value: objects))
         } catch {
            return completion(Result(error: error))
         }
      }
   }
   override func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntity)
      fetchRequest.predicate = search.predicate
      contextSource.performBackgroundTask() { context in
         let results = try? context.fetch(fetchRequest)
         results?.forEach({ context.delete($0) })
         self.saveIn(context: context, completion: completion)
      }
   }
}

