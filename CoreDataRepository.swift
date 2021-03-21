//
//  CoreDataRepository.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation
import CoreData

//MARK:- Helpers for CoreData Rrpository default implementation
protocol DBContextProviding {
   func mainQueueContext() -> NSManagedObjectContext
   func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
}

//MARK:- DB Errors Handling
enum DBRepositoryErrors: Error {
   case entityTypeError
   case noChangesInRepository
}

//MARK:- EntityMapper
class DBEntityMapper<DomainModel, Entity> {
   func convert(_ entity: Entity) -> DomainModel? {
      fatalError("convert(_ entity: Entity: must be overrided")
   }
   func update(_ entity: Entity, by model: DomainModel) {
      fatalError("supdate(_ entity: Entity: must be overrided")
   }
   func entityAccessorKey(_ entity: Entity) -> String {
      fatalError("entityAccessorKey must be overrided")
   }
   func entityAccessorKey(_ object: DomainModel) -> String {
      fatalError("entityAccessorKey must be overrided")
   }
}

final class DBRepository<DomainModel, DBEntity>: Repository<DomainModel>, NSFetchedResultsControllerDelegate {
   
   private let associatedEntityName: String
   private let contextSource: DBContextProviding
   private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
   private var searchedData: Observable<[DomainModel]>?
   private let entityMapper: DBEntityMapper<DomainModel, DBEntity>
   
   
   init(contextSource: DBContextProviding, autoUpdateSearchRequest: RepositorySearchRequest?, entityMapper: DBEntityMapper<DomainModel, DBEntity>) {
      self.contextSource = contextSource
      self.associatedEntityName = String(describing: DBEntity.self)
      self.entityMapper = entityMapper
      
      super.init()
      guard let request = autoUpdateSearchRequest else { return }
      self.searchedData  = .init(value: [])
      self.fetchedResultsController = configureactualSearchedDataUpdating(request)
   }
   
   //MARK: - Private methods for DBRepository usage
   private func applyChanges(context: NSManagedObjectContext, mergePolicy: Any = NSMergeByPropertyObjectTrumpMergePolicy, completion: ((Result<Void>) -> Void)? = nil) {
      context.mergePolicy = mergePolicy
      switch context.hasChanges {
      case true:
         do {
            try context.save()
         } catch {
            ConsoleLog.logEvent(object: "DBRepository \(DBEntity.self)", method: "saveIn", "Error: \(error)")
            completion?(Result.error(error))
         }
         ConsoleLog.logEvent(object: "DBRepository \(DBEntity.self)", method: "saveIn", "Saving Complete")
         completion?(Result(value: ()))
      case false:
         ConsoleLog.logEvent(object: "DBRepository \(DBEntity.self)", method: "saveIn", "No changes in context")
         completion?(Result(error: DBRepositoryErrors.noChangesInRepository))
      }
   }
   private func saveIn(data: [DomainModel], clearBeforeSaving: RepositorySearchRequest?, completion: @escaping ((Result<Void>) -> Void))  {
      contextSource.performBackgroundTask() { context in
         
         if let clearBeforeSaving = clearBeforeSaving {
            let clearFetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.associatedEntityName)
            clearFetchRequest.predicate = clearBeforeSaving.predicate
            clearFetchRequest.includesPropertyValues = false
            (try? context.fetch(clearFetchRequest))?.forEach({ context.delete($0) })
         }
         
         var existingObjects: [String: DBEntity] = [:]
         let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: self.associatedEntityName)
         
         (try? context.fetch(fetchRequest) as? [DBEntity])?.forEach({
            let accessor = self.entityMapper.entityAccessorKey($0)
            existingObjects[accessor] = $0
         })
         
         data.forEach({
            let accessor = self.entityMapper.entityAccessorKey($0)
            let entityForUpdate: DBEntity? = existingObjects[accessor] ??  NSEntityDescription.insertNewObject(forEntityName: self.associatedEntityName, into: context) as? DBEntity
            
            guard let entity = entityForUpdate else { return }
            self.entityMapper.update(entity, by: $0)
         })
         self.applyChanges(context: context, completion: completion)
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
      if let content = fetchedResultsController.fetchedObjects as? [DBEntity] {
         updateObservableContent(content)
      }
      return fetchedResultsController
   }
   
   
   
   //MARK: - Overriding default Repository implementation
   override var actualSearchedData: Observable<[DomainModel]>? {
      return searchedData
   }
   
   override func save(_ objects: [DomainModel], completion: @escaping ((Result<Void>) -> Void)) {
      saveIn(data: objects, clearBeforeSaving: nil, completion: completion)
   }
   override func save(_ objects: [DomainModel], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      saveIn(data: objects, clearBeforeSaving: clearBeforeSaving, completion: completion)
   }
   
   override func present(by request: RepositorySearchRequest, completion: @escaping ((Result<[DomainModel]>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntityName)
      fetchRequest.predicate = request.predicate
      fetchRequest.sortDescriptors = request.sortDescriptors
      contextSource.performBackgroundTask() { context in
         do {
            let rawData = try context.fetch(fetchRequest)
            guard rawData.isEmpty == false else {return completion(Result(value: [])) }
            guard let results = rawData as? [DBEntity] else {
               completion(Result(value: []))
               return assert(false, DBRepositoryErrors.entityTypeError.localizedDescription)
            }
            let transformed = results.compactMap({ return self.entityMapper.convert($0) })
            return completion(Result(value: transformed))
         } catch {
            return completion(Result(error: error))
         }
      }
   }
   
   override func delete(by request: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: associatedEntityName)
      fetchRequest.predicate = request.predicate
      fetchRequest.includesPropertyValues = false
      contextSource.performBackgroundTask() { context in
         let results = try? context.fetch(fetchRequest)
         results?.forEach({ context.delete($0) })
         self.applyChanges(context: context, completion: completion)
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
            ConsoleLog.logEvent(object: "DBRepository \(DBEntity.self)", method: "eraseAllData", "Error: \(error)")
            completion(Result.error(error))
         }
      })
   }
   
   //MARK: - NSFetchedResultsControllerDelegate implementation
   func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      guard let fetchedObjects = controller.fetchedObjects as? [DBEntity] else { return }
      updateObservableContent(fetchedObjects)
   }
   
   func updateObservableContent(_ content: [DBEntity]) {
      let transformed = content.compactMap({ return self.entityMapper.convert($0) })
      searchedData?.value = transformed
   }
}
