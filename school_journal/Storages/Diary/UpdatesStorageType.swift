//
//  UpdatesStorageType.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift

protocol UpdatesStorageType {

    func save(updateds: [Update], name: String) -> Observable<[Update]>
    func updates(for userId: String) -> Observable<[Update]>
    func add(updateds: [Update]) -> Observable<[Update]>
    func deleteAll() -> Observable<Void>
}
