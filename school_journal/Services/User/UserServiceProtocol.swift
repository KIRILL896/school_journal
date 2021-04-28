//
//  UserServiceProtocol.swift
//  scool_journal
//
//  Created by отмеченные on 05/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift

protocol UserServiceType {

    func auth(login: String, password: String, vendor: String) -> Single<(String, Date)>
    func getRules() -> Single<User>
    func setPushToken(token: String, activate: Bool) -> Single<Void>
}
