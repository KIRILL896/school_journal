//
//  UserStorage.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift
import RealmSwift

class UserStorage: UserStorageType {

    private struct Keys {

        static let prefferedStudentNameKey = "ru.scool_journal.PREFFERED_STUDENT_NAME_KEY"
    }

    private var storage: RealmStorage
    private var userDefaults: UserDefaults

    init(config: Realm.Configuration? = nil) {
        storage = RealmStorage(configuration: config)
        userDefaults = UserDefaults()
    }

    func save(user: User) -> Observable<Void> {
        return Observable<Void>.create { observer -> Disposable in
            do {
                try self.addUser(user)
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    func deleteUser() -> Observable<Void> {
        return Observable<Void>.create { observer -> Disposable in
            do {
                try self.wipe()
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    var currentUser: Observable<User> {
        return Observable<User>.create { observer -> Disposable in
            do {
                let user = try self.getCurrentUser()
                observer.onNext(user)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }
    }

    private func addUser(_ user: User) throws {
        try wipe()
        try storage.save(objects: user.students)
        try storage.save(objects: user.schools)
        try storage.save(objects: user.groups)
        try storage.save(object: user)
    }

    private func wipe() throws {
        try storage.deleteAll(ofType: Student.self)
        try storage.deleteAll(ofType: Group.self)
        try storage.deleteAll(ofType: School.self)
        try storage.deleteAll(ofType: User.self)
    }

    private func getCurrentUser() throws -> User {
        let array: [User] = storage.cachedPlainObjects()
        if array.isEmpty {
            throw RuntimeError("No users found")
        }
        if array.count > 1 {
            throw RuntimeError("Many users found")
        }
        guard var user = array.first else { throw RuntimeError("No users found") }
        user.schools = storage.cachedPlainObjects()
        user.groups = storage.cachedPlainObjects()
        user.students = storage.cachedPlainObjects()
        return user
    }

    var perfferedStudentName: String? {
        return userDefaults.string(forKey: Keys.prefferedStudentNameKey)
    }

    func setPrefferedStudentName(_ name: String) {
        userDefaults.set(name, forKey: Keys.prefferedStudentNameKey)
        userDefaults.synchronize()
    }
}
