//
//  LoginViewModel.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift
import RxCocoa

typealias LoginInfo = (token: String, login: String, vendor: String, expDate: Date)

protocol LoginViewModelProtocol {

    var loading: Driver<Bool>! { get }
    var errorOccured: Driver<String>! { get }
    var wrongInput: Driver<Void>! { get }
    var schoolName: Driver<String?>! { get }
    var savedLogin: Driver<String>! { get }

    var loggedIn: Driver<Void>! { get }

    var wantsToOpenSchoolPicker: Driver<Void>! { get }

    func configure(bindings: LoginViewModelBindings)
}

struct LoginViewModelBindings {

    let didPressSchoolTextField: Driver<Void>
    let didPressSearchIcon: Driver<Void>
    let didPressGosuslugiButton: Driver<Void>
    let passwordString: Driver<String>
    let loginString: Driver<String>
    let didPressLoginButton: Driver<Void>
    let didPressRemoveSchool: Driver<Void>
}

class LoginViewModel: BaseViewModel, LoginViewModelProtocol {

    typealias Dependency = HasUserService & HasCredentialsStorage & HasUserStorage & HasDiaryService & HasPeriodsStorage

    var loading: Driver<Bool>!
    var errorOccured: Driver<String>!
    var wantsToOpenSchoolPicker: Driver<Void>!
    var wrongInput: Driver<Void>!
    var schoolName: Driver<String?>!
    var savedLogin: Driver<String>!

    var loggedIn: Driver<Void>!
    private var loggedInSubject = PublishSubject<Void>()
    var credentialsFromEsia = PublishSubject<LoginInfo>()
    let schoolSubject = PublishSubject<SchoolSearchItem?>()
    let saveCredentialsSubject = PublishSubject<Bool>()

    var loginRouter: LoginRouter
    var dependencies: Dependency

    init(loginRouter: LoginRouter, dependencies: Dependency) {
        self.loginRouter = loginRouter
        self.dependencies = dependencies
        loggedIn = loggedInSubject.asObservable().asDriverOnErrorJustComplete()
    }

    private func isAvailableLogin(_ roles: [Role]) -> Bool {
        return roles.count > 0
            && (!roles.contains(.parent) || !roles.contains(.student))
    }

    private func isAvailableTeacherApp(_ roles: [Role]) -> Bool {
        return roles.count > 0
            && (roles.contains(.teacher) || roles.contains(.administrator))
    }

    private func isWrongRolesNotTeacherApp(_ roles: [Role]) -> Bool {
        return roles.count > 0 && !isAvailableLogin(roles) && !isAvailableTeacherApp(roles)
    }

    private func isWrongRolesTeacherApp(_ roles: [Role]) -> Bool {
        return roles.count > 0 && !isAvailableLogin(roles) && isAvailableTeacherApp(roles)
    }

    func configure(bindings: LoginViewModelBindings) {

        let deps = dependencies
        let activityTracker = ActivityIndicator()
        let errorTracker = ErrorTracker()

        let savedLoginDriver = Observable<String?>
            .just(deps.credentialsStorage.savedLogin)
            .compactMap({ $0 })
            .asDriverOnErrorJustComplete()
        let savedSchoolDriver = Observable<SchoolSearchItem?>
            .just(deps.credentialsStorage.savedSchool)
            .asDriverOnErrorJustComplete()
        let loginDriver = Driver<String>
            .merge([savedLoginDriver, bindings.loginString])
            .debug("ololo loginDriver")
        let schoolDriver = Driver<SchoolSearchItem?>
            .merge([schoolSubject.asDriverOnErrorJustComplete(), savedSchoolDriver])

        let input = Driver.combineLatest(loginDriver,
                                         bindings.passwordString,
                                         schoolDriver)

        let inputIsValid = input.map({ (login, password, school) in
            return !login.isEmpty && !password.isEmpty && school != nil
        })

        wrongInput = bindings.didPressLoginButton
            .withLatestFrom(inputIsValid)
            .filter({
                !$0
            })
        .map({ _ in () })

        let request = bindings.didPressLoginButton
            .withLatestFrom(inputIsValid)
            .filter({ $0 })
            .withLatestFrom(input)
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler.defaultScheduler)
            .flatMap({ (login, password, school) -> Observable<User> in
                return deps.userService
                    .auth(login: login, password: password, vendor: school!.value)
                    .asObservable()
                    .do(onNext: { (token, date) in
                        deps.credentialsStorage.token = token
                        deps.credentialsStorage.tokenExpirationDate = date
                        deps.credentialsStorage.domain = school!.value
                        deps.credentialsStorage.savedSchool = school
                        deps.credentialsStorage.savedLogin = login
                    })
                    .flatMap({ _ -> Observable<User> in
                        return deps.userService.getRules().asObservable()
                    })
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .catchError({ _ in return .empty() })
            }).share()

        let esiaRequest = credentialsFromEsia
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler.defaultScheduler)
            .do(onNext: { tuple in
                deps.credentialsStorage.token = tuple.token
                deps.credentialsStorage.tokenExpirationDate = tuple.expDate
                deps.credentialsStorage.domain = tuple.vendor
                let school = SchoolSearchItem(label: "", title: "", value: tuple.vendor)
                deps.credentialsStorage.savedSchool = school
                deps.credentialsStorage.savedLogin = tuple.login
            })
            .flatMap({ _ -> Observable<User> in
                return deps.userService
                    .getRules()
                    .asObservable()
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .catchError({ _ in return .empty() })
            })
            .share()

        // Login error: not teacher app role
        Observable.merge(request, esiaRequest)
            .filter({ return self.isWrongRolesNotTeacherApp($0.roles) })
            .asDriverOnErrorJustComplete()
            .do(onNext: { _ in
                deps.credentialsStorage.token = nil
                deps.credentialsStorage.tokenExpirationDate = nil
                deps.credentialsStorage.domain = nil
            })
            .drive(onNext: { [weak self] _ in
                self?.loginRouter.showEmptyRolesWarning()
            })
            .disposed(by: disposeBag)

        // Login error: teacher app roles
        Observable.merge(request, esiaRequest)
            .filter({ return self.isWrongRolesTeacherApp($0.roles) })
            .asDriverOnErrorJustComplete()
            .do(onNext: { _ in
                deps.credentialsStorage.token = nil
                deps.credentialsStorage.tokenExpirationDate = nil
                deps.credentialsStorage.domain = nil
            })
            .drive(onNext: { [weak self] _ in
                self?.loginRouter.showTeacherWarning()
            })
            .disposed(by: disposeBag)

        // Login error: no roles
        Observable.merge(request, esiaRequest)
            .filter({ $0.roles.isEmpty })
            .asDriverOnErrorJustComplete()
            .do(onNext: { _ in
                deps.credentialsStorage.token = nil
                deps.credentialsStorage.tokenExpirationDate = nil
                deps.credentialsStorage.domain = nil
            })
            .drive(onNext: { [weak self] _ in
                self?.loginRouter.showEmptyRolesWarning()
            })
            .disposed(by: disposeBag)

        // Login ok: from credentials
        let loggingFromCredentials = request
            .filter({ return self.isAvailableLogin($0.roles) })
            .flatMapLatest({ user -> Observable<Bool> in
                deps.userStorage.save(user: user)
                    .flatMap({ deps.userStorage.save(user: user) })
                    .flatMap({ deps.diaryService.periods(for: nil, weeks: true, showDisabled: true).asObservable() })
                    .flatMap({ deps.periodsStorage.save(periods: $0) })
                    .map({
                        _ in true
                    })
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .catchError({ _ in return .just(false) })
            }).share()

        // Login ok: from ESIA
        let loggingFromEsia = esiaRequest
            .filter({ return self.isAvailableLogin($0.roles) })
            .flatMapLatest({ user -> Observable<Bool> in
                deps.userStorage.save(user: user)
                    .flatMap({ deps.userStorage.save(user: user) })
                    .flatMap({ deps.diaryService.periods(for: nil, weeks: true, showDisabled: true).asObservable() })
                    .flatMap({ deps.periodsStorage.save(periods: $0) })
                    .map({
                        _ in true
                    })
                    .trackActivity(activityTracker)
                    .trackError(errorTracker)
                    .catchError({ _ in return .just(false) })
            }).share()

        let retriveOrSaveCredentials = loggingFromCredentials
            .filter({ $0 })
            .withLatestFrom(input)
            .flatMap { tuple -> Observable<Bool> in // bool - сохранено или нет
                // let server = "eljur.ru" as CFString
                let login = tuple.0 as CFString
                let password = tuple.1
                return Observable<Bool>.create { sub -> Disposable in
                    SecRequestSharedWebCredential(nil, login) { array, error in
                        if array == nil || error != nil {
                            sub.onNext(false)
                            return
                        }
                        guard let credentialsArray = array as? [CFDictionary] else {
                            sub.onNext(false)
                            return
                        }
                        var foundCredentials = false
                        for cfdict in credentialsArray {
                            guard let dict = cfdict as? [String: AnyObject]  else {
                                continue
                            }
                            guard let storedAccount = dict[kSecAttrAccount as String] as? String,
                                let storedPassword = dict[kSecSharedPassword as String] as? String else {
                                continue
                            }
                            if storedAccount == login as String && storedPassword == password {
                                foundCredentials = true
                                break
                            }
                        }
                        sub.onNext(foundCredentials)
                        sub.onCompleted()
                    }
                    return Disposables.create()
                }

            }

        let saveCredsInIcloud = retriveOrSaveCredentials.withLatestFrom(input, resultSelector: { credentialsFound, credsTuple -> (String, String, String, Bool) in
            let server = "eljur.ru"
            let login = credsTuple.0
            let password = credsTuple.1
            return (server, login, password, credentialsFound)
        }).flatMap { tuple -> Observable<Bool> in
            let credentialsFound = tuple.3
            if credentialsFound {
                return .just(true)
            }
            let serverToSave = tuple.0 as CFString
            let loginToSave = tuple.1 as CFString
            let passwordToSave = tuple.2 as CFString
            return Observable<Bool>.create { obs -> Disposable in
                if Constants.inScreenshotMode {
                    obs.onNext(true)
                    obs.onCompleted()
                } else {
                    if #available(iOS 11.0, *) {
                        obs.onNext(true)
                        obs.onCompleted()
                    } else {
                        SecAddSharedWebCredential(serverToSave, loginToSave, passwordToSave) { err in
                            print(err ?? "web credentials saved")
                            obs.onNext(true)
                            obs.onCompleted()
                        }
                    }
                }
                return Disposables.create()
            }
        }

        let loggedInObservable = Observable<Bool>.merge([loggingFromEsia, saveCredsInIcloud])
            .filter({ $0 })
            .take(1)
            .mapToVoid()
        loggedInObservable.bind(to: loggedInSubject).disposed(by: disposeBag)

        loggedIn = loggedInSubject.asDriver(onErrorJustReturn: ())

        bindings.didPressRemoveSchool
            .map({ _ -> SchoolSearchItem? in return nil })
            .drive(schoolSubject)
            .disposed(by: disposeBag)

        wantsToOpenSchoolPicker = Driver.merge(bindings.didPressSearchIcon, bindings.didPressSchoolTextField)
        schoolName = schoolDriver.map({ school -> String? in
            return school?.title
        })
        savedLogin = savedLoginDriver
        wantsToOpenSchoolPicker.drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.loginRouter.openSchoolPicker(schoolObserver: self.schoolSubject.asObserver())
        }).disposed(by: disposeBag)

        _ = bindings.didPressGosuslugiButton.drive(onNext: { [weak self] in
            guard let `self` = self else { return }
            self.loginRouter.openGosuslugiAuthScreen(tokenObserver: self.credentialsFromEsia.asObserver())
        }).disposed(by: disposeBag)

        loading = activityTracker.asDriver()
        errorOccured = errorTracker.asDriver().map({ $0.localizedDescription })
    }
}
