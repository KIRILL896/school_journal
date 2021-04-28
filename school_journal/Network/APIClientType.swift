//
//  APIClientType.swift
//  scool_journal
//
//  Created by отмеченные on 12/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift
import SwiftyJSON

struct APIResults<Element: Decodable>: Decodable {
    let items: [Element]
}

protocol APIClientType {

    func perform(request: APIRequest) -> Single<Data>
    func perform(jsonRequest: APIRequest) -> Single<APIResponse>
    func perform(rawJsonRequest: APIRequest) -> Single<JSON>

    func arrayFromJSON<Element: Decodable>(from request: APIRequest, type: Element.Type) -> Single<APIResults<Element>>
    func entityFrom<Element: Decodable>(request: APIRequest, type: Element.Type) -> Single<Element>
}
