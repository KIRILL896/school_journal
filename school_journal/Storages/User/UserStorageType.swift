//
//  UserStorageProtocol.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//
import Foundation
import RxSwift

protocol UserStorageType {

    func save(user: User) -> Observable<Void>
    func deleteUser() -> Observable<Void>

    var currentUser: Observable<User> { get }

    var perfferedStudentName: String? { get }
    func setPrefferedStudentName(_ name: String)
}
