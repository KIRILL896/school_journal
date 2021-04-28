//
//  GlobalService.swift
//  scool_journal
//
//  Created by отмеченные on 09/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON

class GlobalService: GlobalServiceType {

    private struct Params {

        static let schoolsPath = "schools/all"
        static let queryParam = "value"
    }

    private var apiClient: APIClientType
    private var credentialsStorage: CredentialsStorageType

    init(apiClient: APIClientType, credentialsStorage: CredentialsStorageType) {
        self.apiClient = apiClient
        self.credentialsStorage = credentialsStorage
    }

    func searchSchools(with query: String) -> Single<[SchoolSearchItem]> {

        let request = APIRequest(baseURL: Constants.globalApiUrl,
                                 path: Params.schoolsPath,
                                 parameters: [Params.queryParam: query])

        return apiClient.perform(request: request).flatMap({ data in
            do {
                let json = try JSON(data: data)
                guard let result = json["result"].bool, result == true, let options = json["options"].array else {
                    return .error(APIError.wrongDataFormat(url: request.path))
                }
                let schools = options.compactMap({ SchoolSearchItem(from: $0) })
                return .just(schools)
            } catch {
                return .error(APIError.wrongDataFormat(url: request.path))
            }
        })
    }
}
