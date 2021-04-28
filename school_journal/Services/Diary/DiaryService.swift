//
//  DiaryService.swift
//  scool_journal
//
//  Created by отмеченные on 09/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON
import Alamofire

class DiaryService: ApiServiceProtocol, DiaryServiceType {

    private struct Params {

        static let getupdatesPath = "getupdates"
        static let getperiodsPath = "getperiods"
        static let getmarksPath = "getmarks"
        static let getfinalassessmentsPath = "getfinalassessments"
        static let getschedulePath = "getschedule"
        static let getdiaryPath = "getdiary"
        static let getboardnoticesPath = "getboardnotices"
        static let getboardnoticeinfoPath = "getboardnoticeinfo"
        static let postscheduleextdayPath = "postscheduleextday"

        static let weeksParam = "weeks"
        static let showDisabledParam = "show_disabled"
        static let studentParam = "student"
        static let daysParam = "days"
        static let limitParam = "limit"
        static let registerIdParam = "register_id"
        static let pageParam = "page"
        static let ringsParam = "rings"
        static let classParam = "class"
        static let idParam = "id"
    }

    private var apiClient: APIClientType
    var credentialsStorage: CredentialsStorageType

    init(apiClient: APIClientType, credentialsStorage: CredentialsStorageType) {
        self.apiClient = apiClient
        self.credentialsStorage = credentialsStorage
    }

    func updates(for ids: [String], page: Int, limit: Int) -> Single<[Update]> {
        let params: [String: Any] = [
            Params.studentParam: ids.joined(separator: ","),
            Params.limitParam: limit,
            Params.pageParam: page]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getupdatesPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[Update]> in
            switch response {
            case .success(let data):
                guard let json = data.result, let updatesJSON = json["students"].dictionary else {
                    return .error(APIError.wrongDataFormat(url: "updates"))
                }
                var updates = [Update]()
                for (userId, value) in updatesJSON {
                    if let updatesJSON = value["updates"].dictionary {
                        if let latestJSON = updatesJSON["latest"], let latestArray = latestJSON.array {
                            var fetchedLatest = latestArray.map({ Update(from: $0) })
                            for (index, _) in fetchedLatest.enumerated() {
                                fetchedLatest[index].ownerId = userId
                                fetchedLatest[index].isLatest = true
                                fetchedLatest[index].id = UUID().uuidString
                            }
                            updates.append(contentsOf: fetchedLatest)
                        }
                        if let oldJSON = updatesJSON["old"], let oldArray = oldJSON.array {
                            var fetchedOld = oldArray.map({ Update(from: $0) })
                            for (index, _) in fetchedOld.enumerated() {
                                fetchedOld[index].ownerId = userId
                                fetchedOld[index].isLatest = false
                                fetchedOld[index].id = UUID().uuidString
                            }
                            updates.append(contentsOf: fetchedOld)
                        }
                    }
                }
                return .just(updates)
            case .failure(let err):
                return .error(err)
            }
        }
    }

    func periods(for ids: [String]?, weeks: Bool, showDisabled: Bool) -> Single<[Period]> {
        var params = [String: Any]()
        if let ids = ids {
            params[Params.studentParam] = ids.joined(separator: ",")
        }
        params[Params.weeksParam] = weeks
        params[Params.showDisabledParam] = showDisabled

        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getperiodsPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[Period]> in
            switch response {
            case .success(let data):
                var periods = [Period]()
                guard let json = data.result, let studentsJSON = json["students"].array else {
                    return .just(periods)
                }
                for studentJSON in studentsJSON {
                    guard let studIdInt = studentJSON["name"].int,
                        let periodsArray = studentJSON["periods"].array else {
                        continue
                    }
                    let studId = String(studIdInt)
                    var fetchedPeriods = periodsArray.compactMap({ Period(from: $0) })
                    for (index, _) in fetchedPeriods.enumerated() {
                        fetchedPeriods[index].ownerId = studId
                    }
                    periods.append(contentsOf: fetchedPeriods)
                }
                return .just(periods)
            case .failure(let err):
                return .error(err)
            }
        }
    }

    func marks(for ids: [String]?, period: Period?) -> Single<[Lesson]> {
        var params = [String: Any]()
        if let ids = ids {
            params[Params.studentParam] = ids.joined(separator: ",")
        }
        if let period = period {
            params[Params.daysParam] = period.periodStringRepresentation
        }

        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getmarksPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[Lesson]> in
            switch response {
            case .success(let data):
                var marks = [Lesson]()
                guard let json = data.result, let studentsJSON = json["students"].dictionary else {
                    return .just([])
                }
                for (_, value) in studentsJSON {
                    if let lessonsJSON = value["lessons"].array {
                        marks = lessonsJSON.map({ Lesson(from: $0) })
                    }
                }
                return .just(marks)
            case .failure(let err):
                return .error(err)
            }

        }
    }

    func finalassessments(for ids: [String]?) -> Single<[FinalAssesment]> {
        var params = [String: Any]()
        if let ids = ids {
            params[Params.studentParam] = ids.joined(separator: ",")
        }

        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getfinalassessmentsPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[FinalAssesment]> in
            switch response {
            case .success(let data):
                var marks = [FinalAssesment]()
                guard let json = data.result, let studentsJSON = json["students"].dictionary else {
                    return .error(APIError.dataError(description: "finalassessments"))
                }
                for (_, value) in studentsJSON {
                    if let lessonsJSON = value["items"].array {
                        marks = lessonsJSON.map({ FinalAssesment(from: $0) })
                    }
                }
                return .just(marks)
            case .failure(let err):
                return .error(err)
            }

        }
    }

    func schedule(for id: String, week: Week, rings: Bool, studentClass: String) -> Single<[Schedule]> {
        var params = [String: Any]()
        params[Params.studentParam] = id
        params[Params.daysParam] = week.periodStringRepresentation
        params[Params.ringsParam] = rings
        params[Params.classParam] = studentClass
        var request = APIRequest(baseURL: urlWithVendor,
                                path: Params.getschedulePath,
                                parameters: params,
                                authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[Schedule]> in
            switch response {
            case .success(let data):
                var scheduleArray = [Schedule]()
                guard let json = data.result, let daysJSON = json["days"].dictionary  else {
                    return .error(APIError.dataError(description: "schedule"))
                }
                for (dateStr, value) in daysJSON {
                    var schedule = Schedule(from: value)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyyMMdd"
                    if let date = formatter.date(from: dateStr) {
                        schedule.date = date
                    }
                    scheduleArray.append(schedule)
                }
                return .just(scheduleArray)
            case .failure(let err):
                return .error(err)
            }

        }
    }

    func postscheduleextday(for id: String, registerId: String) -> Single<Void> {
        var params = [String: Any]()
        params[Params.studentParam] = id
        params[Params.registerIdParam] = registerId

        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.postscheduleextdayPath,
                                 parameters: params,
                                 headers: nil,
                                 httpMethod: .post,
                                 encodingType: JSONEncoding.default,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<Void> in
            switch response {
            case .success:
                return .just(())
            case .failure(let err):
                return .error(err)
            }
        }
    }

    func diary(for id: String, week: Week, rings: Bool) -> Single<[Diary]> {
        var params = [String: Any]()
        params[Params.studentParam] = id
        params[Params.daysParam] = week.periodStringRepresentation
        params[Params.ringsParam] = rings
        var request = APIRequest(baseURL: urlWithVendor,
                                path: Params.getdiaryPath,
                                parameters: params,
                                authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[Diary]> in
            switch response {
            case .success(let data):
                var diaryArray = [Diary]()
                guard let json = data.result,
                    let studentsJSON = json["students"].dictionary,
                    let firstStudentJSON = studentsJSON.first  else {
                    return .error(APIError.dataError(description: "diary"))
                }
                if let daysJSON = firstStudentJSON.value["days"].dictionary {
                    for (_, value) in daysJSON {
                        let diary = Diary(from: value)
                        diaryArray.append(diary)
                    }
                }
                return .just(diaryArray)
            case .failure(let err):
                return .error(err)
            }

        }
    }

    func notices(limit: Int, page: Int) -> Single<[Notice]> {
        let params: [String: Any] = [Params.limitParam: limit,
                                       Params.pageParam: page]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getboardnoticesPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }

        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<[Notice]> in
            switch response {
            case .success(let data):

                guard let json = data.result else {
                    return .error(APIError.wrongDataFormat(url: "notices"))
                }
                guard let noticesJSON = json["notices"].array else {
                    return .just([Notice]())
                }

                let notices = noticesJSON.compactMap({ Notice(from: $0) })
                return .just(notices)
            case .failure(let err):
                return .error(err)
            }
        }
    }

    func notice(with id: String) -> Single<Notice> {
        let params: [String: Any] = [Params.idParam: id]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getboardnoticeinfoPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap { response -> Single<Notice> in
            switch response {
            case .success(let data):
                guard let json = data.result, let notice = Notice(from: json["notice"]) else {
                    return .error(APIError.wrongDataFormat(url: "notice"))
                }
                return .just(notice)
            case .failure(let err):
                return .error(err)
            }
        }
    }
}
