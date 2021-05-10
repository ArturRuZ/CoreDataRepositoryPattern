//
//  ViewController.swift
//  CoreDataRepositoryDemo
//
//  Created by Artur Ruzhnikov on 14.03.2021.
//

import UIKit

class ViewController: UIViewController {
   
   private var repository: Repository<Book>?

   override func viewDidLoad() {
      super.viewDidLoad()
      let contextProvider = DBContextProvider()
      let entityMapper = BookEntityMapper()
      let repository = DBRepository(contextSource: contextProvider,
                                autoUpdateSearchRequest: nil,
                                entityMapper: entityMapper)
      self.repository = repository
      prepareForExampleCase3(repository)
   }
   
   func prepareForExampleCase3(_ repository: Repository<Book>) {
      let example = ExampleCase3(repository: repository)
      let books = example.generateMock()
      example.startSaving(books)
   }
}

