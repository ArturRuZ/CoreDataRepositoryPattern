//
//  CoreDataRepository.swift
//
//  Created by Artur Ruzhnikov on 09.02.2021.
//  Copyright © 2021. All rights reserved.
//



// TEMPLATE OF REPOSITORY USAGE
/*
 class TestRepository: Repository<DBRepoRawData, DBRepoExpectedModel> {

 override var actualSearchedData: Observable<[DBRepoExpectedModel]>? {
    return nil
 }
 
 override func save(_ objects: [DBRepoExpectedModel], completion: @escaping ((Result<Void>) -> Void)) {
 }
 override func save(_ rawData: [DBRepoRawData], completion: @escaping ((Result<Void>) -> Void)) {
 }
 override func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[DBRepoExpectedModel]>) -> Void))
 {
 }
 override func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
 }
 }
 */
// Convertable CoreData USAGE
/*
 import Foundation
 import CoreData

 public protocol MockRawData {
    
 }
 public protocol MockModel {
    
 }
 
 @objc(Problems8dEntity)
 public class TestEntity: EntityConvertable<MockRawData, MockModel>  {

    public override func updateSelfFrom(_ model: MockModel) {
       
    }
    public override func updateSelfFrom(_ rawData:  MockRawData) {
       
    }
    public override func transformSelfToModel() -> MockModel? {
       return nil
    }
 }
 */

import Foundation
import CoreData

//MARK: - Common repository protocol + default implementation
protocol AccessableRepository {
   associatedtype RawDataForUpdate
   associatedtype ExpectedModel
   
   var actualSearchedData: Observable<[ExpectedModel]>? {get}
   
   func save(_ rawData: [RawDataForUpdate], completion: @escaping ((Result<Void>) -> Void))
   func save(_ objects: [ExpectedModel], completion: @escaping ((Result<Void>) -> Void))

   func save(_ rawData: [RawDataForUpdate], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   func save(_ objects: [ExpectedModel], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   
   func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[ExpectedModel]>) -> Void))
}

//MARK: - The way of fixing protocol error for generic types for AccessableRepository
class Repository<RepoRawData, RepoDomainExpectedModel>: NSObject, AccessableRepository {
   typealias RawDataForUpdate = RepoRawData
   typealias ExpectedModel = RepoDomainExpectedModel
   
   var actualSearchedData: Observable<[RepoDomainExpectedModel]>? {
      fatalError("actualSearchedData must be overrided")
   }
   
   func save(_ rawData: [RepoRawData], completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("save(_ rawData:) must be overrided")
   }
   func save(_ objects: [RepoDomainExpectedModel], completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("save(_ objects:) must be overrided")
   }
   func save(_ rawData: [RepoRawData], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("save(_ rawData:) must be overrided")
   }
   func save(_ objects: [RepoDomainExpectedModel], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("save(_ objects:) must be overrided")
   }
      
   func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("delete(by search:) must be overrided")
   }
   func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[RepoDomainExpectedModel]>) -> Void)) {
      fatalError("get(by search:) must be overrided")
   }
   func eraseAllData(completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("eraseAllData() must be overrided")
   }
}

//MARK:- CoreData repository

//MARK:- EntityConvertation protocol + implementation
//protocol EntityConvertation where Self: NSManagedObject   {
//   associatedtype RawDataForUpdate
//   associatedtype ExpectedModel
//   
//   func updateSelfFrom(_ rawData: RawDataForUpdate)
//   func updateSelfFrom(_ model: ExpectedModel)
//   func transformSelfToModel() -> ExpectedModel?
//}

class DBEntityConverter<RawDataForUpdate, ExpectedModel, Entity> {
   func update(entity: Entity, rawData: RawDataForUpdate) {
      fatalError("update(entity:) must be overrided")
   }
   func update(entity: Entity,_ model: ExpectedModel) {
      fatalError("update(entity:) must be overrided")
   }
   func convert(entity: Entity) -> ExpectedModel? {
      fatalError("transform(entity:) must be overrided")
   }
   func getEntityAccessor(for model: ExpectedModel) -> String? {
      fatalError("getEntityAccessor(for model:) must be overrided")
   }
   func getEntityAccessor(for rawData: RawDataForUpdate) -> String? {
      fatalError("getEntityAccessor(for rawData:) must be overrided")
   }
   func getEntityAccessor(for entity: Entity) -> String? {
      fatalError("getEntityAccessor(for entity:) must be overrided")
   }
}

//MARK: The way of fixing protocol error for generic types for EntityConvertation
//public class EntityConvertable<RawData, DomainModel>: NSManagedObject, EntityConvertation {
//   public typealias RawDataForUpdate = RawData
//   public typealias ExpectedModel = DomainModel
//
//   public func updateSelfFrom(_ rawData: RawData) {}
//   public func updateSelfFrom(_ model: DomainModel) {}
//   public func transformSelfToModel() -> DomainModel? { return nil }
//}

//MARK:- Helpers for CoreData Rrpository default implementation
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
struct AllSearchRequest: RepositorySearchRequest {
   var predicate: NSPredicate? = nil
   var sortDescriptors: [NSSortDescriptor] = []
}

enum DBRepositoryErrors: Error {
   case entityTypeError
   case noChangesInRepository
}
//extension DBRepositoryErrors: LocalizedError {
//
//}


//MARK: - CoreData repository default implementation
final class DBRepository<DBRepoRawData, DBRepoExpectedModel, DBRepoEntity: NSManagedObject>: Repository<DBRepoRawData, DBRepoExpectedModel>, NSFetchedResultsControllerDelegate  {
   
   private let associatedEntityName: String
   private let contextSource: DBContextProviding
   private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
   private var searchedData: Observable<[DBRepoExpectedModel]>?
   private let entityConverter: EntityConverter<DBRepoRawData, DBRepoExpectedModel, DBRepoEntity>
   
   private func saveIn(context: NSManagedObjectContext, mergePolicy: Any = NSMergeByPropertyObjectTrumpMergePolicy, completion: ((Result<Void>) -> Void)? = nil) {
      context.mergePolicy = mergePolicy
      switch context.hasChanges {
      case true:
         do {
            try context.save()
         } catch {
            ConsoleLog.logEvent(object: "DBRepository \(DBRepoEntity.self)", method: "saveIn", "Error: \(error)")
            completion?(Result.error(error))
         }
         ConsoleLog.logEvent(object: "DBRepository \(DBRepoEntity.self)", method: "saveIn", "Saving Complete")
         completion?(Result(value: ()))
      case false:
         ConsoleLog.logEvent(object: "DBRepository \(DBRepoEntity.self)", method: "saveIn", "No changes in context")
         completion?(Result(error: DBRepositoryErrors.noChangesInRepository))
      }
   }
   
   private func configureactualSearchedDataUpdating(_ request: RepositorySearchRequest) -> NSFetchedResultsController<NSFetchRequestResult> {
      let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: associatedEntityName)

      fetchRequest.predicate = request.predicate
      fetchRequest.sortDescriptors = request.sortDescriptors
      
      let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                managedObjectContext: contextSource.mainQueueContext(), sectionNameKeyPath: nil,
                                                                    cacheName: nil)
      fetchedResultsController.delegate = self
      try? fetchedResultsController.performFetch()
      if let content = fetchedResultsController.fetchedObjects as? [DBRepoEntity] {
         updateObservableContent(content)
      }
      
      return fetchedResultsController

   }
   
   private func save<T>(data: [T], clearBeforeSaving: RepositorySearchRequest?, completion: @escaping ((Result<Void>) -> Void))  {
      contextSource.performBackgroundTask() { context in
         func applySaving(existingObjects: [String: DBRepoEntity]) {
            data.forEach({
               switch $0 {
               case let object as DBRepoRawData:
                  guard let accessor = self.entityConverter.getEntityAccessor(for: object),
                        let entity = existingObjects[accessor] else {
                     guard let entity = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? DBRepoEntity else { return }
                     self.entityConverter.update(entity: entity, rawData: object)
                     return
                  }
                  self.entityConverter.update(entity: entity, rawData: object)
               case let object as DBRepoExpectedModel:
                  guard let accessor = self.entityConverter.getEntityAccessor(for: object),
                        let entity = existingObjects[accessor] else {
                     guard let entity = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? DBRepoEntity else { return }
                     self.entityConverter.update(entity: entity, object)
                     return
                  }
                  self.entityConverter.update(entity: entity, object)
               default:
                  break
               }
            })
            self.saveIn(context: context, completion: completion)
         }
       
         // TO DO - Check case when CoreData not update someValues
         guard let _ = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? DBRepoEntity else { completion(Result(error: DBRepositoryErrors.entityTypeError))
            return assert(false, DBRepositoryErrors.entityTypeError.localizedDescription)
         }
         
         let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.associatedEntityName)
      
         guard let clearBeforeSaving = clearBeforeSaving else {
            var dictionary: [String: DBRepoEntity] = [:]
            (try? context.fetch(fetchRequest) as? [DBRepoEntity])?.forEach({
               guard let key = self.entityConverter.getEntityAccessor(for: $0) else { return }
               dictionary[key] = $0
            })
            return applySaving(existingObjects: [:])
         }
      
         fetchRequest.predicate = clearBeforeSaving.predicate
         fetchRequest.includesPropertyValues = false
         (try? context.fetch(fetchRequest))?.forEach({ context.delete($0) })
      
         applySaving(existingObjects: [:])
         }
      }
   
   init(contextSource: DBContextProviding, entityConverter: EntityConverter<DBRepoRawData, DBRepoExpectedModel, DBRepoEntity>, autoUpdateSearchRequest: RepositorySearchRequest?) {
      self.associatedEntityName = String(describing: DBRepoEntity.self)
      self.contextSource = contextSource
      self.entityConverter = entityConverter
      super.init()
      
      guard let request = autoUpdateSearchRequest else { return  }
      self.fetchedResultsController = configureactualSearchedDataUpdating(request)
      self.searchedData  = .init(value: [])
   }
   
   //MARK: - Overriding default Repository implementation
   override var actualSearchedData: Observable<[DBRepoExpectedModel]>? {
      return searchedData
   }
   
   override func save(_ objects: [DBRepoExpectedModel], completion: @escaping ((Result<Void>) -> Void)) {
      save(data: objects, clearBeforeSaving: nil, completion: completion)
   }
   override func save(_ objects: [Repository<DBRepoRawData, DBRepoExpectedModel>.ExpectedModel], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      save(data: objects, clearBeforeSaving: clearBeforeSaving, completion: completion)
   }
   override func save(_ rawData: [DBRepoRawData], completion: @escaping ((Result<Void>) -> Void)) {
      save(data: rawData, clearBeforeSaving: nil, completion: completion)
   }
   override func save(_ rawData: [Repository<DBRepoRawData, DBRepoExpectedModel>.RawDataForUpdate], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      save(data: rawData, clearBeforeSaving: clearBeforeSaving, completion: completion)
   }
   override func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[DBRepoExpectedModel]>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntityName)
      fetchRequest.predicate = search.predicate
      fetchRequest.sortDescriptors = search.sortDescriptors
      contextSource.performBackgroundTask() { context in
         do {
            let rawData = try context.fetch(fetchRequest)
            guard rawData.isEmpty == false else {return completion(Result(value: [])) }
            guard let results = rawData as? [DBRepoEntity] else {
               completion(Result(value: []))
               return assert(false, DBRepositoryErrors.entityTypeError.localizedDescription)
            }
            let transformed = results.compactMap({ return self.entityConverter.transform(entity: $0) })
            return completion(Result(value: transformed))
         } catch {
            return completion(Result(error: error))
         }
      }
   }
   override func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntityName)
      fetchRequest.predicate = search.predicate
      fetchRequest.includesPropertyValues = false
      contextSource.performBackgroundTask() { context in
         let results = try? context.fetch(fetchRequest)
         results?.forEach({ context.delete($0) })
         self.saveIn(context: context, completion: completion)
      }
   }
   override func eraseAllData(completion: @escaping ((Result<Void>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: associatedEntityName)
      let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
      batchDeleteRequest.resultType = .resultTypeObjectIDs
      contextSource.performBackgroundTask({ context in
         do {
             let result = try context.execute(batchDeleteRequest)
             guard let deleteResult = result as? NSBatchDeleteResult,
                 let ids = deleteResult.result as? [NSManagedObjectID]
             else { return   completion(Result.error(DBRepositoryErrors.noChangesInRepository)) }

             let changes = [NSDeletedObjectsKey: ids]
             NSManagedObjectContext.mergeChanges(
                 fromRemoteContextSave: changes,
               into: [self.contextSource.mainQueueContext()]
             )
            return completion(Result(value: ()))
         } catch {
            ConsoleLog.logEvent(object: "DBRepository \(DBRepoEntity.self)", method: "eraseAllData", "Error: \(error)")
            completion(Result.error(error))
         }
      })
   }

   //MARK: - NSFetchedResultsControllerDelegate implementation
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      guard let fetchedObjects = controller.fetchedObjects as? [DBRepoEntity] else { return }
      updateObservableContent(fetchedObjects)
   }
   
   func updateObservableContent(_ content: [DBRepoEntity]) {
      let transformed = content.compactMap({ return self.entityConverter.convert(entity: $0) })
      searchedData?.value = transformed
   }
}
