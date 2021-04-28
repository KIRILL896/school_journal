//
//  APIResponseData.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import SwiftyJSON

struct APIResponseData {

    var state: Int
    var error: String?
    var result: JSON?

    init?(from json: JSON) {
        let response = json["response"]
        guard let state = response["state"].int  else {
            return nil
        }
        self.state = state
        self.error = response["error"].string
        self.result = response["result"]
    }
}
