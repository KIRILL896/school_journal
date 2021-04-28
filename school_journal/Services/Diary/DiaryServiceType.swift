//
//  DiaryServiceType.swift
//  scool_journal
//
//  Created by отмеченные on 09/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift

protocol DiaryServiceType {

    func updates(for ids: [String], page: Int, limit: Int) -> Single<[Update]>
    func periods(for ids: [String]?, weeks: Bool, showDisabled: Bool) -> Single<[Period]>
    func marks(for ids: [String]?, period: Period?) -> Single<[Lesson]>
    func finalassessments(for ids: [String]?) -> Single<[FinalAssesment]>
    func schedule(for id: String, week: Week, rings: Bool, studentClass: String) -> Single<[Schedule]>
    func diary(for id: String, week: Week, rings: Bool) -> Single<[Diary]>
    func notices(limit: Int, page: Int) -> Single<[Notice]>
    func notice(with id: String) -> Single<Notice>
    func postscheduleextday(for id: String, registerId: String) -> Single<Void>
}
