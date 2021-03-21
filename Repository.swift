//
//  Repository.swift
//  CoreDataRepository
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation

//MARK:- Repository protocol
protocol AccessableRepository {
   associatedtype DomainModel
   
   var actualSearchedData: Observable<[DomainModel]>? {get}
   
   func save(_ objects: [DomainModel], completion: @escaping ((Result<Void>) -> Void))
   func save(_ objects: [DomainModel], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   
   func present(by request: RepositorySearchRequest, completion: @escaping ((Result<[DomainModel]>) -> Void))
   
   func delete(by request: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   func eraseAllData(completion: @escaping ((Result<Void>) -> Void))
}

protocol RepositorySearchRequest {
   /* NSPredicate = nil,  apply for all records
    for deletion sortDescriptor is not Used
    */
   var predicate: NSPredicate? {get}
   var sortDescriptors: [NSSortDescriptor] {get}
}

//MARK: - Default Repository implementation
class Repository<DomainModel>: NSObject, AccessableRepository {
   typealias DomainModel = DomainModel
   
   var actualSearchedData: Observable<[DomainModel]>? {
      fatalError("actualSearchedData must be overrided")
   }
   
   func save(_ objects: [DomainModel], completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("save(_ objects: must be overrided")
   }
   func save(_ objects: [DomainModel], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("save(_ objects vs clearBeforeSaving: must be overrided")
   }
   
   func present(by request: RepositorySearchRequest, completion: @escaping ((Result<[DomainModel]>) -> Void)) {
      fatalError("present(by request: must be overrided")
   }
   
   func delete(by request: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("delete(by request: must be overrided")
   }
   func eraseAllData(completion: @escaping ((Result<Void>) -> Void)) {
      fatalError("eraseAllData(completion: must be overrided")
   }
}

//MARK: - Entity Converter for Repository
class EntityConverter<SourceObject, TargetObject> {
   func convert(_ object: SourceObject) -> TargetObject? {
      fatalError("convert(_ object:must be overrided")
   }
}
