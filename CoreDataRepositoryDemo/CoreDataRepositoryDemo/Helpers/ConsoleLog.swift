//
//  ConsoleLog.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import Foundation

final class ConsoleLog {
   static private let isEnabled = true
   static private func log(_ any: Any, _ force: Bool) {
        if force || isEnabled {  print (any) }
     }
   static func logEvent(object: String, method: String, _ value: String?, force: Bool = false) {
      let text = method + "@" + object + ": " + (value ?? "nil")
      Self.log(text, force)
   }
   static func logRequest(_ url: URL?, data: Data, force: Bool = false) {
      Self.log("== REQUEST DATA: ==========================================", force)
      Self.log(url as Any, force)
      Self.log(String(data: data, encoding: .utf8) as Any, force)
      Self.log("============================================ END REQUEST ==", force)
   }
   static func logResponse(_ url: URL?, data: Data, force: Bool = false) {
      Self.log("== RESPONSE DATA: ==========================================", force)
      Self.log(url as Any, force)
      Self.log(String(data: data, encoding: .utf8) as Any, force)
      Self.log("============================================ END REQUEST ==", force)
   }
   static func logResponseError(_ url: URL?, error: Error?, force: Bool = false) {
      Self.log("== RESPONSE ERROR: ==========================================", force)
      Self.log(url as Any, force)
      Self.log(error as Any, force)
      Self.log("============================================ END REQUEST ==", force)
   }
   static func logDeinit(_ name: String, force: Bool = false) {
      Self.log("===\(name) deinit===", force)
     }
}
