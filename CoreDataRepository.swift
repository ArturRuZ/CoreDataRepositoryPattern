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
   func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[ExpectedModel]>) -> Void))
}

//MARK: - The way of fixing protocol error for generic types for AccessableRepository
class Repository<RepoRawData, RepoDomainExpectedModel>: NSObject, AccessableRepository {
   typealias RawDataForUpdate = RepoRawData
   typealias ExpectedModel = RepoDomainExpectedModel
   
   var actualSearchedData: Observable<[RepoDomainExpectedModel]>? { nil }
   
   func save(_ rawData: [RepoRawData], completion: @escaping ((Result<Void>) -> Void)) {}
   func save(_ objects: [RepoDomainExpectedModel], completion: @escaping ((Result<Void>) -> Void)) {}
   func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {}
   func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[RepoDomainExpectedModel]>) -> Void)) {}
}

//MARK:- CoreData repository

//MARK:- EntityConvertation protocol + implementation
protocol EntityConvertation where Self: NSManagedObject   {
   associatedtype RawDataForUpdate
   associatedtype ExpectedModel
   
   func updateSelfFrom(_ rawData: RawDataForUpdate)
   func updateSelfFrom(_ model: ExpectedModel)
   func transformSelfToModel() -> ExpectedModel?
}

//MARK: The way of fixing protocol error for generic types for EntityConvertation
public class EntityConvertable<RawData, DomainModel>: NSManagedObject, EntityConvertation {
   public typealias RawDataForUpdate = RawData
   public typealias ExpectedModel = DomainModel
   
   public func updateSelfFrom(_ rawData: RawData) {}
   public func updateSelfFrom(_ model: DomainModel) {}
   public func transformSelfToModel() -> DomainModel? { return nil }
}

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

enum DBRepositoryErrors: Error {
   case entityConvertableMissing
   case noChangesInBase
}
//extension DBRepositoryErrors: LocalizedError {
//
//}

//MARK: - CoreData repository default implementation
final class DBRepository<DBRepoRawData, DBRepoExpectedModel, DBRepoGettingFilter>: Repository<DBRepoRawData, DBRepoExpectedModel>, NSFetchedResultsControllerDelegate  {
   
   private let associatedEntityName: String
   private let contextSource: DBContextProviding
   private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
   private var searchedData: Observable<[DBRepoExpectedModel]>?
   
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
         completion?(Result(error: DBRepositoryErrors.noChangesInBase))
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
      
      return fetchedResultsController

   }
   
   init(associatedEntityName: String, contextSource: DBContextProviding, autoUpdateSearchRequest: RepositorySearchRequest?) {
      self.associatedEntityName = associatedEntityName
      self.contextSource = contextSource
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
      contextSource.performBackgroundTask() { context in
         // TO DO - Check case when CoreData not update someValues
         guard let _ = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? EntityConvertable<DBRepoRawData, DBRepoExpectedModel> else { completion(Result(error: DBRepositoryErrors.entityConvertableMissing))
            return assert(false, DBRepositoryErrors.entityConvertableMissing.localizedDescription)
         }
         
         objects.forEach({
            let entity = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? EntityConvertable<DBRepoRawData, DBRepoExpectedModel>
            entity?.updateSelfFrom($0)
         })
         self.saveIn(context: context, completion: completion)
      }
   }
   override func save(_ rawData: [DBRepoRawData], completion: @escaping ((Result<Void>) -> Void)) {
      contextSource.performBackgroundTask() { context in
         // TO DO - Check case when CoreData not update someValues
         guard let _ = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? EntityConvertable<DBRepoRawData, DBRepoExpectedModel> else { completion(Result(error: DBRepositoryErrors.entityConvertableMissing))
            return assert(false, DBRepositoryErrors.entityConvertableMissing.localizedDescription)
         }
         
         rawData.forEach({
            let entity = NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? EntityConvertable<DBRepoRawData, DBRepoExpectedModel>
            entity?.updateSelfFrom($0)
         })
         self.saveIn(context: context, completion: completion)
      }
   }
   override func get(by search: RepositorySearchRequest, completion: @escaping ((Result<[DBRepoExpectedModel]>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntityName)
      fetchRequest.predicate = search.predicate
      fetchRequest.sortDescriptors = search.sortDescriptors
      contextSource.performBackgroundTask() { context in
         do {
            let rawData = try context.fetch(fetchRequest)
            guard rawData.isEmpty == false else {return completion(Result(value: [])) }
            guard let results = rawData as? [EntityConvertable<DBRepoRawData, DBRepoExpectedModel>] else {
               completion(Result(value: []))
               return assert(false, DBRepositoryErrors.entityConvertableMissing.localizedDescription)
            }
            let transformed = results.compactMap({ return $0.transformSelfToModel() })
            return completion(Result(value: transformed))
         } catch {
            return completion(Result(error: error))
         }
      }
   }
   override func delete(by search: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntityName)
      fetchRequest.predicate = search.predicate
      contextSource.performBackgroundTask() { context in
         let results = try? context.fetch(fetchRequest)
         results?.forEach({ context.delete($0) })
         self.saveIn(context: context, completion: completion)
      }
   }
   
   //MARK: - NSFetchedResultsControllerDelegate implementation
   func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      guard let fetchedObjects = controller.fetchedObjects as? [EntityConvertable<DBRepoRawData, DBRepoExpectedModel>] else { return }
      let transformed = fetchedObjects.compactMap({ return $0.transformSelfToModel() })
      searchedData?.value = transformed
   }
}
