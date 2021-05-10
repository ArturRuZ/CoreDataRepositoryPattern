//
//  Result.swift
//  CoreDataRepository
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation

enum Result<Value> {
  case success(Value)
  case error(Error)
  
  init(value: Value) {
    self = .success(value)
  }
  init(error: Error) {
    self = .error(error)
  }
  
  var success: Value? {
    switch self {
    case .success(let value): return value
    case .error: return nil
    }
  }
  var error: Error? {
    switch self {
    case .success: return nil
    case .error(let error): return error
    }
  }
}
