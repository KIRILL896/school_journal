//
//  PeriodsStorageType.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift

protocol PeriodsStorageType {

    func save(periods: [Period]) -> Observable<[Period]>
    func periods(for userId: String) -> Observable<[Period]>
    func deleteAll() -> Observable<Void>
}
