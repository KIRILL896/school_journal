//
//  UpdatesStorage.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RealmSwift
import RxSwift

class UpdatesStorage: UpdatesStorageType {

    private var storage: RealmStorage

    init(config: Realm.Configuration? = nil) {
        storage = RealmStorage(configuration: config)
    }

    func save(updateds: [Update], name: String) -> Observable<[Update]> {
        return Observable<[Update]>.create { observer in
            do {
                let predicate = NSPredicate(format: "ownerId == %@", name)
                let array: [Update] = self.storage.cachedPlainObjects(predicate: predicate)
                try self.storage.deleteAll(objects: array)

                try self.storage.save(objects: updateds)
                observer.onNext(updateds)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func add(updateds: [Update]) -> Observable<[Update]> {
        return Observable<[Update]>.create { observer in
            do {
                try self.storage.save(objects: updateds)
                observer.onNext(updateds)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func deleteAll() -> Observable<Void> {
        return Observable<Void>.create { observer in
            do {
                try self.storage.deleteAll(ofType: Update.self)
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func updates(for name: String) -> Observable<[Update]> {
        let predicate = NSPredicate(format: "ownerId == %@", name)
        let obs: Observable<[Update]> = self.storage.cachedPlainObjectsUpdatable(predicate: predicate)
        return obs
    }

}
