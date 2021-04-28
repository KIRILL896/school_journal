//
//  LoginViewController.swift
//  scool_journal
//
//  Created by отмеченные on 11/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxKeyboard
import RxGesture

class LoginViewController: ViewController, UITextFieldDelegate {

    let disposeBag = DisposeBag()

    var viewModel: LoginViewModelProtocol!

    var keyboardDisposable: Disposable?

    let didPressSendButton = PublishSubject<Void>()

    @IBOutlet weak var vSchoolInputContainer: UIView!
    @IBOutlet weak var tvScoolName: Label!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var vInputContainer: UIView!
    @IBOutlet weak var vShoolIconsContainer: UIView!
    @IBOutlet weak var ivRemoveIcon: UIImageView!
    @IBOutlet weak var ivSearchIcon: UIImageView!
    @IBOutlet weak var tvLogin: TextField!
    @IBOutlet weak var tvPassword: TextField!
    @IBOutlet weak var btnLogin: EjLoginButton!
    @IBOutlet weak var btnLoginWithGosuslugi: EjLoginButton!
    @IBOutlet weak var lbVersion: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)
        setupViews()
        setupViewModel()
        setupBindings()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default
            .removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default
            .removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        var inset = UIEdgeInsets.zero
        var offset: CGFloat = 0.0
        if notification.name == UIResponder.keyboardWillHideNotification {
            inset = .zero
        } else {
            offset = 120.0
            inset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }

        scrollView.scrollIndicatorInsets = inset
        scrollView.contentInset = inset
        scrollView.setContentOffset(CGPoint(x: 0.0, y: offset), animated: true)
//        let selectedRange = yourTextView.selectedRange
//        yourTextView.scrollRangeToVisible(selectedRange)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    func setupViews() {
        if Constants.inScreenshotMode {
            lbVersion.text = ""
        } else {
            lbVersion.text = L10n.About.version(
                Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0.0")
        }

        btnLogin.setTitle(L10n.Login.loginButtonTitle, for: .normal)

        vInputContainer.layer.cornerRadius = 8
        vInputContainer.layer.masksToBounds = true

        tvScoolName.textColor = Colors.loginScreenInputFieldPlaceholder
        tvScoolName.text = L10n.Login.schoolPlaceholder

        var loginPlaceholder = NSMutableAttributedString()
        let lpText = L10n.Login.loginPlaceholder
        loginPlaceholder = NSMutableAttributedString(
            string: lpText, attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),
                NSAttributedString.Key.foregroundColor: Colors.loginScreenInputFieldPlaceholder
            ])
        tvLogin.attributedPlaceholder = loginPlaceholder
        tvLogin.delegate = self

        var passwordPlaceholder = NSMutableAttributedString()
        let psText = L10n.Login.passwordPlaceholder
        passwordPlaceholder = NSMutableAttributedString(
            string: psText, attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17),
                NSAttributedString.Key.foregroundColor: Colors.loginScreenInputFieldPlaceholder
            ])
        tvPassword.attributedPlaceholder = passwordPlaceholder
        tvPassword.delegate = self

        ivSearchIcon.isHidden = false
        ivRemoveIcon.isHidden = true

        hideKeyboardWhenTappedAround()
        scrollView.keyboardDismissMode = .interactive
        scrollView.delaysContentTouches = false

        let image = Assets.Images.gosuslugiLogo.image
        let btnTitle = NSMutableAttributedString(
            string: L10n.Login.loginWithGosuslugiButtonTitle + "  ",
            attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium),
                NSAttributedString.Key.foregroundColor: Colors.mainTheme
            ]
        )
        let attachment = NSTextAttachment()
        attachment.image = image
        let offsetY: CGFloat = -3
        let newBounds = CGRect(x: 0, y: offsetY, width: image.size.width, height: image.size.height)
        attachment.bounds = newBounds
        let iconString = NSAttributedString(attachment: attachment)
        btnTitle.append(iconString)
        btnLoginWithGosuslugi.setAttributedTitle(btnTitle, for: .normal)

        btnLogin.rx.tap.subscribe(onNext: { [weak self] in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)

        btnLoginWithGosuslugi.rx.tap.subscribe(onNext: { [weak self] in
            self?.view.endEditing(true)
        }).disposed(by: disposeBag)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === tvLogin {
            tvPassword.becomeFirstResponder()
        } else if textField === tvPassword {
            didPressSendButton.onNext(())
            textField.resignFirstResponder()
        }
        return false
    }

    func setupViewModel() {
        let didPressSchoolTextField = tvScoolName.rx
            .tapGesture()
            .when(.recognized)
            .asDriverOnErrorJustComplete()
            .map({ _ in () })

        let didPressSearchIcon = ivSearchIcon.rx
            .tapGesture()
            .when(.recognized)
            .asDriverOnErrorJustComplete()
            .map({ _ in () })
        let didPressGosuslugiButton = btnLoginWithGosuslugi.rx
            .tap
            .asDriver()
        let passwordString = tvPassword.rx.text.orEmpty.asDriver().startWith("")
        let loginString = tvLogin.rx.text.orEmpty.asDriver().startWith("")
        let didPressLoginButton = Driver.merge([didPressSendButton.asDriverOnErrorJustComplete(),
                                                btnLogin.rx.tap.asDriver()])
        let didPressRemoveSchool = ivRemoveIcon.rx
            .tapGesture()
            .when(.recognized)
            .asDriverOnErrorJustComplete()
            .map({ _ in () })
        let bindings = LoginViewModelBindings(didPressSchoolTextField: didPressSchoolTextField,
                                              didPressSearchIcon: didPressSearchIcon,
                                              didPressGosuslugiButton: didPressGosuslugiButton,
                                              passwordString: passwordString,
                                              loginString: loginString,
                                              didPressLoginButton: didPressLoginButton,
                                              didPressRemoveSchool: didPressRemoveSchool)
        viewModel.configure(bindings: bindings)
    }

    func setupBindings() {
        viewModel.wrongInput.drive(onNext: { [weak self] in
            self?.vInputContainer.shake()
        }).disposed(by: disposeBag)
        viewModel.schoolName.drive(onNext: { [weak self] name in
            if name == nil {
                self?.tvScoolName.text = L10n.Login.schoolPlaceholder
                self?.tvScoolName.textColor = Colors.loginScreenInputFieldPlaceholder
                self?.ivSearchIcon.isHidden = false
                self?.ivRemoveIcon.isHidden = true
            } else {
                self?.tvScoolName.textColor = UIColor.black
                self?.tvScoolName.text = name
                self?.ivSearchIcon.isHidden = true
                self?.ivRemoveIcon.isHidden = false
            }
        }).disposed(by: disposeBag)

        viewModel.loading.drive(onNext: { [weak self] loading in
            if loading {
                self?.showProgress()
            } else {
                self?.hideProgressView()
            }
        }).disposed(by: disposeBag)

        viewModel.errorOccured.drive(onNext: { [weak self] error in
            self?.showErrorToast(with: error)
        }).disposed(by: disposeBag)
        viewModel.savedLogin.drive(onNext: { [weak self] text in
            self?.tvLogin.text = text
            self?.tvLogin.sendActions(for: .valueChanged)
        }).disposed(by: disposeBag)
    }
}
