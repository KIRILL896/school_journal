//
//  APIRequest.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import Alamofire

enum AuthorizationType {
    case none
    case token
}

struct APIRequest {

    var baseURL: String
    var path: String
    var headers = [String: String]()
    var parameters = [String: Any]()
    var httpMethod: HTTPMethod
    var encodingType: ParameterEncoding
    var authType: AuthorizationType

    init(
        baseURL: String,
        path: String = "",
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        httpMethod: HTTPMethod = .get,
        encodingType: ParameterEncoding = URLEncoding.default,
        authType: AuthorizationType = .none
    ) {
        self.baseURL = baseURL
        self.path = path
        if let _ = headers, headers!.count > 0 {
            self.headers.update(other: headers!)
        }
        if let _ = parameters, parameters!.count > 0 {
            self.parameters.update(other: parameters!)
        }
        self.httpMethod = httpMethod
        self.encodingType = encodingType
        self.authType = authType
    }
}
