//
//  PeriodStorage.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RealmSwift
import RxSwift

class PeriodStorage: PeriodsStorageType {

    private var storage: RealmStorage

    init(config: Realm.Configuration? = nil) {
        storage = RealmStorage(configuration: config)
    }

    func save(periods: [Period]) -> Observable<[Period]> {
        return Observable<[Period]>.create { observer in
            do {
                let array: [Period] = self.storage.cachedPlainObjects()
                let weeks = array.compactMap({ $0.weeks }).flatMap({ $0 })
                try self.storage.deleteAll(objects: weeks)
                try self.storage.deleteAll(objects: array)
                let newWeeks = periods.compactMap({ $0.weeks }).flatMap({ $0 })
                try self.storage.save(objects: newWeeks)
                try self.storage.save(objects: periods)
                observer.onNext(periods)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func periods(for userId: String) -> Observable<[Period]> {
        let predicate = NSPredicate(format: "ownerId == %@", userId)
        let obs: Observable<[Period]> = self.storage.cachedPlainObjectsObservable(predicate: predicate)
        return obs
    }

    func deleteAll() -> Observable<Void> {
        return Observable<Void>.create { observer in
            do {
                try self.storage.deleteAll(ofType: Period.self)
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }
}
