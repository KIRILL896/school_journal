//
//  GlobalServiceProtocol.swift
//  scool_journal
//
//  Created by отмеченные on 09/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift

protocol GlobalServiceType {

    func searchSchools(with query: String) -> Single<[SchoolSearchItem]>
}
