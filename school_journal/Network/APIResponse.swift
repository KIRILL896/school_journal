//
//  APIResponse.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//
import Foundation
import SwiftyJSON

enum APIResponse {
    case success(APIResponseData)
    case failure(Error)
}
