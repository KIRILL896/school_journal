//
//  PushService.swift
//  scool_journal
//
//  Created by отмеченные on 17/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift

class PushService {

    typealias Dependency = HasUserService & HasCredentialsStorage
    var dependencies: Dependency
    var sendingDisposable: Disposable?

    init(dependencies: Dependency) {
        self.dependencies = dependencies
    }

    func saveNewToken(_ token: String) {
        let credentialsStorage = dependencies.credentialsStorage
        if credentialsStorage.pushToken != token {
            credentialsStorage.pushToken = token
            credentialsStorage.pushTokenIsSent = false
            checkTokenAndSend()
        }
    }

    func checkTokenAndSend() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus == .authorized else { return }

            self?.sendToken()
        }
    }

    func sendToken() {
        let creds = dependencies.credentialsStorage
        guard let _ = creds.domain, let _ = creds.token, let token = creds.pushToken, !creds.pushTokenIsSent else {
            return
        }
        sendingDisposable = dependencies.userService
            .setPushToken(token: token, activate: true)
            .do(onSuccess: { [weak self] in
                self?.dependencies.credentialsStorage.pushTokenIsSent = true
            })
            .debug("ololo setPushToken")
            .catchErrorJustReturn(())
            .subscribe()
    }

    func invalidate() {
        sendingDisposable?.dispose()
    }
}
