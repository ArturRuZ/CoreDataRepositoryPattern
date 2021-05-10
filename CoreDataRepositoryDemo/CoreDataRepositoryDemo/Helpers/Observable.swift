//
//  Observable.swift
//  CoreDataRepository
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation

final class Observable<T> {
  
  //MARK:- Properties
  
  typealias CompletionHandler = ((T) -> Void)
  var value : T {
    didSet {
      self.notifyObservers(self.observers)
    }
  }
  private var observers : [String : CompletionHandler] = [:]
  
  //MARK:- Private methods
  
  private func notifyObservers(_ observers: [String : CompletionHandler]) {
     observers.forEach({ $0.value(value) })
   }
  
  //MARK:- Initialization
  
  init(value: T) {
    self.value = value
  }
  deinit {
     observers.removeAll()
   }
}

final class Observer {
  var description: String

  init (description: String) {
    self.description = description
  }
}
