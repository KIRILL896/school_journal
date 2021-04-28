//
//  BaseService.swift
//  scool_journal
//
//  Created by отмеченные on 09/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation

protocol ApiServiceProtocol {

    var credentialsStorage: CredentialsStorageType { get set }
    func addDefaultHeaders(to apiRequest: inout APIRequest) throws
    func addDefaultParams(to apiRequest: inout APIRequest, addVendor: Bool) throws
    var urlWithVendor: String { get }
}

extension ApiServiceProtocol {

    var urlWithVendor: String {
        guard let vendorStr = credentialsStorage.domain else {
            NotificationCenter.default.post(name: InAppNotifications.TokenOrCredentialsAreInvalid, object: nil)
            return ""
        }
        return credentialsStorage.apiUrl.replacingOccurrences(of: Constants.vendorPlaceholder, with: vendorStr)
    }

    func addDefaultHeaders(to apiRequest: inout APIRequest) throws {

    }

    func addDefaultParams(to apiRequest: inout APIRequest, addVendor: Bool = true) throws {
        var paramsToAdd = [String: Any]()
        switch apiRequest.authType {
        case .token:
            guard let token = credentialsStorage.token else {
                NotificationCenter.default.post(name: InAppNotifications.TokenOrCredentialsAreInvalid, object: nil)
                throw RuntimeError("token is needed for \(apiRequest.baseURL + apiRequest.path)")
            }
            paramsToAdd["auth_token"] = token
        default:
            break
        }
        paramsToAdd["devkey"] = credentialsStorage.devKey
        paramsToAdd["out_format"] = "json"
        if addVendor {
            guard let vendor = credentialsStorage.domain else {
                NotificationCenter.default.post(name: InAppNotifications.TokenOrCredentialsAreInvalid, object: nil)
                throw RuntimeError("token is needed for \(apiRequest.baseURL + apiRequest.path)")
            }
            paramsToAdd["vendor"] = vendor
        }

        apiRequest.parameters.update(other: paramsToAdd)
    }
}
