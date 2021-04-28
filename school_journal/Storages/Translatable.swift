//
//  Translatable.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RealmSwift

protocol Translatable: Identifiable {

    associatedtype ManagedObject: Object

    init(object: ManagedObject)
    func toManagedObject() -> ManagedObject
}

protocol Identifiable {

    var uniqueIdetifier: AnyHashable { get }
}
