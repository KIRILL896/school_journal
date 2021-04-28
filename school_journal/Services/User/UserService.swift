//
//  UserService.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift

class UserService: ApiServiceProtocol, UserServiceType {
    private struct Params {

        static let authPath = "auth"
        static let getRulesPath = "getrules"
        static let setpushtokenPath = "setpushtoken"

        static let loginParam = "login"
        static let tokenParam = "token"
        static let activateParam = "activate"
        static let typeParam = "type"
        static let vendorParam = "vendor"
        static let passwordParam = "password"
    }

    private var apiClient: APIClientType
    var credentialsStorage: CredentialsStorageType

    init(apiClient: APIClientType, credentialsStorage: CredentialsStorageType) {
        self.apiClient = apiClient
        self.credentialsStorage = credentialsStorage
    }

    func auth(login: String, password: String, vendor: String) -> Single<(String, Date)> {
        credentialsStorage.domain = vendor
        let params = [
            Params.loginParam: login,
            Params.passwordParam: password,
            Params.vendorParam: vendor
        ]
        let baseURL = urlWithVendor
        var request = APIRequest(
            baseURL: baseURL,
            path: Params.authPath,
            parameters: params
        )
        do {
            try addDefaultParams(to: &request, addVendor: false)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap({ response in
            switch response {
            case .success(let data):
                let json = data.result
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                guard let token = json?["token"].string, let expiresString = json?["expires"].string else {
                    CrashlyticsHelper.recordErrorAsync(
                        NSError(
                            domain: "WrongDataFormat: auth",
                            code: 1_000_019,
                            userInfo: [
                                "Auth-Login": login,
                                "Auth-Domain": vendor,
                                "Auth-Token": json?["token"].string ?? "nil",
                                "Auth-Expires": json?["expires"].string ?? "nil"
                            ]
                        )
                    )
                    return .error(APIError.wrongDataFormat(url: "auth"))
                }
                guard let expiresDate = formatter.date(from: expiresString) else {
                    CrashlyticsHelper.recordErrorAsync(
                        NSError(
                            domain: "WrongDataFormat: auth",
                            code: 1_000_020,
                            userInfo: [
                                "Auth-Login": login,
                                "Auth-Domain": vendor,
                                "Auth-Token": json?["token"].string ?? "nil",
                                "Auth-Expires": json?["expires"].string ?? "nil",
                                "Auth-DateFormatter-Locale": formatter.locale.identifier,
                                "Auth-System-Locale": NSLocale.current.identifier
                            ]
                        )
                    )
                    return .error(APIError.wrongDataFormat(url: "auth"))
                }
                return .just((token, expiresDate))
            case .failure(let err):
                return .error(err)
            }
        })
    }

    func getRules() -> Single<User> {
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.getRulesPath,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap({ response in
            switch response {
            case .success(let data):
                let json = data.result
                guard let userJSON = json, let user = User(from: userJSON) else {
                    return .error(APIError.wrongDataFormat(url: "getRules"))
                }
                return .just(user)
            case .failure(let err):
                return .error(err)
            }
        })
    }

    func setPushToken(token: String, activate: Bool) -> Single<Void> {
        let params: [String: Any] = [
            Params.tokenParam: token,
            Params.typeParam: "apple",
            Params.activateParam: activate
        ]
        var request = APIRequest(baseURL: urlWithVendor,
                                 path: Params.setpushtokenPath,
                                 parameters: params,
                                 authType: .token)
        do {
            try addDefaultParams(to: &request)
        } catch {
            return .error(error)
        }
        return apiClient.perform(jsonRequest: request).flatMap({ response in
            switch response {
            case .success:
                return .just(())
            case .failure(let err):
                return .error(err)
            }
        })
    }
}
