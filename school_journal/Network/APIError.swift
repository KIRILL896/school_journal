//
//  Error.swift
//  scool_journal
//
//  Created by отмеченные on 11/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//
import Foundation

enum APIError: Swift.Error, LocalizedError {

    case wrongURL(url: String)
    case noInternetConnection
    case emptyResponse
    case emptyData
    case wrongDataFormat(url: String)
    case dataError(description: String)
    case responseError(code: Int, description: String)
    case accessForbidden

    var errorDescription: String? {
        switch self {
        case .wrongURL(let url):
            return L10n.Errors.wrongUrl(url)
        case .noInternetConnection:
            return L10n.Errors.noInternetConnection
        case .emptyResponse:
            return L10n.Errors.emptyResponse
        case .emptyData:
            return L10n.Errors.emptyData
        case .wrongDataFormat(let url):
            return L10n.Errors.wrongDataFormat(url)
        case .dataError(let description):
            return L10n.Errors.dataError(description)
        case .responseError(_, let description):
            return description
        case .accessForbidden:
            return L10n.Errors.accessFrobidden
        }
    }

}
