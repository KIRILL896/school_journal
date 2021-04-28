//
//  BaseRouter.swift
//  scool_journal
//
//  Created by отмеченные on 1/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import UIKit
import RxSwift

class BaseRouter {

    let disposeBag = DisposeBag()

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController
    }

    weak var sourceViewController: UIViewController?
}
