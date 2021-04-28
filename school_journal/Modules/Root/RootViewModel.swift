//
//  RootControllerViewModel.swift
//  scool_journal
//
//  Created by отмеченные on 01/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol RootViewModelProtocol {

    var items: Driver<[MenuItem]>! { get }
    var didReceivePush: Driver<Push>! { get }
    func configure(bindings: RootViewModelBindings)
}

struct RootViewModelBindings {

    let logout: Driver<Void>
}

class RootViewModel: BaseViewModel, RootViewModelProtocol {

    typealias Dependency = HasUserService & HasUserStorage & HasCredentialsStorage
        & HasMessagesStorage & HasMessagesService
        & HasUpdatesStorage & HasPeriodsStorage & HasNoticesStorage
    var dependencies: Dependency
    var logoutObserver: AnyObserver<Void>?
    var items: Driver<[MenuItem]>!
    var didReceivePush: Driver<Push>!

    let rootTabRouterLoadedSubject = PublishSubject<Void>()

    func rootTabRouterDidLoad() {
        rootTabRouterLoadedSubject.onNext(())
    }

    init(dependencies: Dependency, logoutObserver: AnyObserver<Void>?) {
        self.logoutObserver = logoutObserver
        self.dependencies = dependencies

        CrashlyticsHelper.setDomain(dependencies.credentialsStorage.domain ?? "unknown")
        CrashlyticsHelper.setLogin(dependencies.credentialsStorage.savedLogin ?? "unknown")
    }

    func configure(bindings: RootViewModelBindings) {
        let deps = dependencies
        let userObservable = dependencies.userStorage.currentUser
        items = userObservable.map { user -> [MenuItem] in
            var items = [MenuItem]()
            if user.allowedSection.contains(.updates) {
                items.append(MenuItem(section: .updates, batch: nil))
            }
            if user.allowedSection.contains(.diary) {
                items.append(MenuItem(section: .diary, batch: nil))
            }

            items.append(MenuItem(section: .notices, batch: nil))

            if user.allowedSection.contains(.messages) {
               items.append(MenuItem(section: .messages, batch: "100"))
            }
            return items
        }.asDriver(onErrorJustReturn: [])

        let wipeObservable = Observable.concat([ deps.credentialsStorage.wipeObservable(),
                                                 deps.userStorage.deleteUser(),
                                                 deps.messagesStorage.deleteAll(),
                                                 deps.updatesStorage.deleteAll(),
                                                 deps.periodsStorage.deleteAll(),
                                                 deps.noticesStorage.deleteAll()]).toArray()
        bindings.logout.asObservable().flatMap {
            return wipeObservable
        }.subscribe(onNext: { [weak self] _ in
            CrashlyticsHelper.resetCurrent()
            CrashlyticsHelper.setDomain("nil")
            CrashlyticsHelper.setLogin("nil")

            UIApplication.shared.applicationIconBadgeNumber = 0
            self?.logoutObserver?.onNext(())
        }).disposed(by: disposeBag)

        let invalidCredentialsNotification = NotificationCenter.default.rx
            .notification(InAppNotifications.TokenOrCredentialsAreInvalid)

        let updateMessagesFromNotification = NotificationCenter.default.rx
            .notification(InAppNotifications.NotificationReceived)
            .mapToVoid()

        let loadMessagesTrigger = Observable.merge([updateMessagesFromNotification, rootTabRouterLoadedSubject])

        let messagesRequest = loadMessagesTrigger
            .observeOn(ConcurrentDispatchQueueScheduler.userInitiated)
            .flatMap { _ -> Observable<[Message]> in
                return deps.messagesService
                    .messages(type: .inbox, limit: Constants.updatesLoadingPageSize, page: 1).asObservable()
                    .flatMap({ fetchedMessages -> Observable<[Message]> in
                        return deps.messagesStorage.add(messages: fetchedMessages)
                    })
                    .catchError({ _ in return .empty() })
            }.share()
        messagesRequest.subscribe().disposed(by: disposeBag)

        deps.messagesStorage.messages(for: .inbox).subscribe(onNext: { msgs in
        DispatchQueue.main.async {
          let unreadCount = msgs.filter({ $0.type == .inbox && $0.isUnread }).count
          UIApplication.shared.applicationIconBadgeNumber = unreadCount
        }
      }).disposed(by: disposeBag)

        invalidCredentialsNotification
            .flatMap { _ in
                wipeObservable
            }
            .mapToVoid()
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] in
                CrashlyticsHelper.resetCurrent()
                CrashlyticsHelper.setDomain("nil")
                CrashlyticsHelper.setLogin("nil")

                UIApplication.shared.applicationIconBadgeNumber = 0
                self?.logoutObserver?.onNext(())
            })
            .disposed(by: disposeBag)

        didReceivePush = NotificationCenter.default.rx
            .notification(InAppNotifications.NotificationReceived)
            .map({ $0.userInfo })
            .compactMap({ $0 })
            .map({ Push(info: $0) })
            .compactMap({ $0 })
            .asDriverOnErrorJustComplete()

    }
}
