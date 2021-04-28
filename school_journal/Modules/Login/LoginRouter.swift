//
//  LoginRouter.swift
//  scool_journal
//
//  Created by отмеченные on 12/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LoginRouter: BaseRouter {

    typealias Dependency = HasGlobalService & HasCredentialsStorage
    var dependencies: Dependency

    init(sourceViewController: UIViewController?, dependencies: Dependency) {
        self.dependencies = dependencies
        super.init(sourceViewController: sourceViewController)
    }

    func openSchoolPicker(schoolObserver: AnyObserver<SchoolSearchItem?>) {
        let vc = SchoolSearchController.instanceFromStoryboard()
        let vm = SchoolsSearchViewModel(dependency: dependencies)
        vc.viewModel = vm
        vm.schoolPicked.drive(onNext: { [weak self] school in
            schoolObserver.onNext(school)
            self?.sourceViewController?.navigationController?.popToRootViewController(animated: true)
        }).disposed(by: vm.disposeBag)
        self.sourceViewController?.navigationController?.pushViewController(vc, animated: true)
    }

    func openGosuslugiAuthScreen(tokenObserver: AnyObserver<LoginInfo>) {
        let vc = AuthWebViewController()
        vc.tokenObserver = tokenObserver
        let nvc = UINavigationController(rootViewController: vc)
        let closeButton = UIBarButtonItem(image: Assets.Images.icClose.image, style: .plain, target: nil, action: nil)
        guard let url = URL(string: dependencies.credentialsStorage.esiaUrl) else { return }
        vc.url = url
        vc.navigationItem.leftBarButtonItems = [closeButton]
        closeButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.sourceViewController?.dismiss(animated: true, completion: nil)
        }).disposed(by: vc.disposeBag)
        self.sourceViewController?.present(nvc, animated: true, completion: nil)
    }

    func showSaveCredentialsPrompt(observer: AnyObserver<Bool>) {
        let alert = UIAlertController(
            title: nil, message: L10n.Login.saveCredentialsPrompt, preferredStyle: .actionSheet)
        let saveAction = UIAlertAction(title: L10n.Login.savePassword, style: .default) { _ in
            observer.onNext(true)
        }
        let notNowAction = UIAlertAction(title: L10n.Common.notNow, style: .cancel) { _ in
            observer.onNext(false)
        }
        alert.addAction(saveAction)
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            let notNowAIPadction = UIAlertAction(title: L10n.Common.notNow, style: .default) { _ in
                observer.onNext(false)
            }
            alert.addAction(notNowAIPadction)
        }
        alert.addAction(notNowAction)
        alert.view.tintColor = Colors.mainTheme
        if let svc = sourceViewController {
            alert.popoverPresentationController?.sourceView = svc.view
            alert.popoverPresentationController?.sourceRect = CGRect(
                x: svc.view.bounds.midX, y: svc.view.bounds.midY,
                width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
        }
        if let _ = sourceViewController?.presentedViewController {
            sourceViewController?.dismiss(animated: false, completion: {
                self.sourceViewController?.present(alert, animated: true, completion: nil)
            })
        } else {
            self.sourceViewController?.present(alert, animated: true, completion: nil)
        }
    }

    func showTeacherWarning() {
        let alert = UIAlertController(
            title: L10n.Common.error, message: L10n.Login.teacherWarning, preferredStyle: .alert)
        let yesAction = UIAlertAction(title: L10n.Common.yes, style: .default) { _ in
            if let url = URL(string: ""),
            UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let noAction = UIAlertAction(title: L10n.Common.no, style: .default, handler: nil)
        alert.addAction(noAction)
        alert.addAction(yesAction)
        if let svc = sourceViewController {
            alert.popoverPresentationController?.sourceView = svc.view
            alert.popoverPresentationController?.sourceRect = CGRect(
                x: svc.view.bounds.midX, y: svc.view.bounds.midY,
                width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
        }
        if let _ = sourceViewController?.presentedViewController {
            sourceViewController?.dismiss(animated: false, completion: {
                self.sourceViewController?.present(alert, animated: true, completion: nil)
            })
        } else {
            self.sourceViewController?.present(alert, animated: true, completion: nil)
        }
    }

    func showEmptyRolesWarning() {
        let alert = UIAlertController(
            title: L10n.Common.error, message: L10n.Login.emptyRolesWarning, preferredStyle: .alert)
        let okAction = UIAlertAction(title: L10n.Common.ok, style: .default, handler: nil)
        alert.addAction(okAction)
        if let svc = sourceViewController {
            alert.popoverPresentationController?.sourceView = svc.view
            alert.popoverPresentationController?.sourceRect = CGRect(
                x: svc.view.bounds.midX, y: svc.view.bounds.midY,
                width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
        }
        if let _ = sourceViewController?.presentedViewController {
            sourceViewController?.dismiss(animated: false, completion: {
                self.sourceViewController?.present(alert, animated: true, completion: nil)
            })
        } else {
            self.sourceViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
