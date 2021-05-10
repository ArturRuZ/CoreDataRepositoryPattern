//
//  Repository.swift
//  CoreDataRepository
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation

//MARK:- Repository protocol
protocol AccessableRepository {
   //1
   associatedtype DomainModel
   //2
   var actualSearchedData: Observable<[DomainModel]>? {get}
   
   //3
   func save(_ objects: [DomainModel], completion: @escaping ((Result<Void>) -> Void))
   //4
   func save(_ objects: [DomainModel], clearBeforeSaving: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   
   //5
   func present(by request: RepositorySearchRequest, completion: @escaping ((Result<[DomainModel]>) -> Void))
   
   //6
   func delete(by request: RepositorySearchRequest, completion: @escaping ((Result<Void>) -> Void))
   //7
   func eraseAllData(completion: @escaping ((Result<Void>) -> Void))
}

protocol RepositorySearchRequest {
   /* NSPredicate = nil,  apply for all records
    for deletion sortDescriptor is not Used
    */
   //1
   var predicate: NSPredicate? {get}
   //2
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
