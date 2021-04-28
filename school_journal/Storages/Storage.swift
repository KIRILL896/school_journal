//
//  Storage.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

protocol StorageProtocol: class {

    func cachedPlainObjects<T: Translatable>() -> [T]
    func object<T: Translatable>(byPrimaryKey key: AnyHashable) -> T?
    func save<T: Translatable>(objects: [T]) throws
    func save<T: Translatable>(object: T) throws
    func delete<T: Translatable>(object: T) throws
    func deleteAll<T: Translatable>(ofType type: T.Type) throws
}

class RealmStorage {

    var configuration: Realm.Configuration?

    init(configuration: Realm.Configuration?) {
        self.configuration = configuration
    }

    fileprivate var realmInstance: Realm {
        var realm: Realm!
        do {
            if let cfg = self.configuration {
                realm = try Realm(configuration: cfg)
            } else {
                var config = Realm.Configuration()
                config.schemaVersion = 7
                config.deleteRealmIfMigrationNeeded = true
                realm = try Realm(configuration: config)
            }
        } catch {
            print("Failed to instantiate realm")
        }
        return realm
    }

    func cachedPlainObjects<T: Translatable>(predicate: NSPredicate? = nil) -> [T] {
        let realm = realmInstance
        var resultArray = [T.ManagedObject]()
        if predicate != nil {
            resultArray = Array(realm.objects(T.ManagedObject.self).filter(predicate!))
        } else {
            resultArray = Array(realm.objects(T.ManagedObject.self))
        }
        let translatedObjects = resultArray.map { T(object: $0) }
        return translatedObjects
    }

    func cachedPlainObjectsObservable<T: Translatable>(predicate: NSPredicate? = nil) -> Observable<[T]> {
        let realm = realmInstance
        var resultArray: Results<T.ManagedObject>
        if let predicate = predicate {
            resultArray = realm.objects(T.ManagedObject.self).filter(predicate)
        } else {
            resultArray = realm.objects(T.ManagedObject.self)
        }
        return .just(resultArray.map({ T(object: $0) }))
    }

    func cachedPlainObjectsUpdatable<T: Translatable>(predicate: NSPredicate? = nil) -> Observable<[T]> {
        let realm = realmInstance
        var resultArray: Results<T.ManagedObject>
        if let predicate = predicate {
            resultArray = realm.objects(T.ManagedObject.self).filter(predicate)
        } else {
            resultArray = realm.objects(T.ManagedObject.self)
        }
        let updateablePlainObservable = Observable.collection(from: resultArray)
            .map({manObjs in
                return Array(manObjs).map({ T(object: $0) })
            })
        return updateablePlainObservable
    }

    func object<T: Translatable>(byPrimaryKey key: AnyHashable) -> T? {
        let realm = realmInstance
        guard let realmObject = realm.object(ofType: T.ManagedObject.self, forPrimaryKey: key) else { return nil }
        let translatedObject = T(object: realmObject)
        return translatedObject
    }

    @discardableResult
    func save<T: Translatable>(objects: [T]) throws -> [Object] {
        let realm = realmInstance
        let realmObjects = objects.map { $0.toManagedObject() }
        try realm.write {
            realm.add(realmObjects, update: .modified)
        }
        return realmObjects
    }

    @discardableResult
    func save<T: Translatable>(object: T) throws -> Object {
        let realm = realmInstance
        let realmObject = object.toManagedObject()
        try realm.write {
            realm.add(realmObject, update: .modified)
        }
        return realmObject
    }

    func delete<T: Translatable>(object: T) throws {
        let realm = realmInstance
        guard let realmObject = realm.object(ofType: T.ManagedObject.self, forPrimaryKey: object.uniqueIdetifier) else {
            return
        }
        try realm.write {
            realm.delete(realmObject)
        }
    }

    func deleteAll<T: Translatable>(objects: [T]) throws {
        let realm = realmInstance
        let array = objects
            .map({ realm.object(ofType: T.ManagedObject.self, forPrimaryKey: $0.uniqueIdetifier) })
            .compactMap({ $0 })
        try realm.write {
            realm.delete(array)
        }
    }

    func deleteAll<T: Translatable>(ofType type: T.Type) throws {
        let realm = realmInstance
        let realmObjects = Array(realm.objects(T.ManagedObject.self))
        try realm.write {
            realm.delete(realmObjects)
        }

    }
}
