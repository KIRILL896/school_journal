//
//  AuthWebViewController.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import RxSwift

class AuthWebViewController: UIViewController, WKNavigationDelegate {

    let disposeBag = DisposeBag()
    var tokenObserver: AnyObserver<LoginInfo>?

    var webView: WKWebView!

    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        let webViewContainer = self.view!
        let webConfiguration = WKWebViewConfiguration()
        let prefferences = WKPreferences()
        prefferences.javaScriptCanOpenWindowsAutomatically = true
        prefferences.javaScriptEnabled = true
        webConfiguration.preferences = prefferences
        let customFrame = CGRect(
            origin: CGPoint.zero,
            size: CGSize(width: 0.0, height: webViewContainer.frame.size.height)
        )
        let view = WKWebView(frame: customFrame, configuration: webConfiguration)
        view.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.addSubview(view)

        view.topAnchor.constraint(equalTo: webViewContainer.topAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: webViewContainer.rightAnchor).isActive = true
        view.leftAnchor.constraint(equalTo: webViewContainer.leftAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor).isActive = true
        view.heightAnchor.constraint(equalTo: webViewContainer.heightAnchor).isActive = true
        self.webView = view

        [progressView].forEach { self.view.addSubview($0) }
        progressView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor).isActive = true

        if #available(iOS 11.0, *) {
            progressView.topAnchor.constraint(equalTo: webViewContainer.safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            progressView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        }

        progressView.heightAnchor.constraint(equalToConstant: 2).isActive = true

        if let url = url {
            let request = URLRequest(url: url)
            self.webView.load(request)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addObserversAndDelegates()
        CrashlyticsHelper.setScreen(String(describing: type(of: self)))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        removeObserversAndDelegates()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

    }

    // MARK: - методы делегата WKWebView
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let urlStr = navigationAction.request.url?.absoluteString else {
            decisionHandler(.allow)
            return
        }
        _ = checkParameters(in: urlStr)

        decisionHandler(.allow)
    }

    func checkParameters(in string: String) -> Bool {
        guard let tokenRange = string.range(of: "A?token[^&]*", options: .regularExpression),
            let loginRange = string.range(of: "A?login[^&]*", options: .regularExpression),
            let expiresRange = string.range(of: "A?expires[^&]*", options: .regularExpression),
            let vendorRange = string.range(of: "A?vendor[^&]*", options: .regularExpression) else {
                return true
        }

        let tokenSplit = string[tokenRange].split(separator: "=")
        let loginSplit = string[loginRange].split(separator: "=")
        let expiresSplit = string[expiresRange].split(separator: "=")
        let vendorSplit = string[vendorRange].split(separator: "=")

        guard tokenSplit.count == 2, loginSplit.count == 2, expiresSplit.count == 2, vendorSplit.count == 2 else {
            return true
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let token = String(tokenSplit[1])
        let login = String(loginSplit[1])
        let vendor = String(vendorSplit[1])

        guard let expires = String(expiresSplit[1]).removingPercentEncoding?.replacingOccurrences(of: "+", with: " "),
            let expDate = formatter.date(from: expires)else {
            return true
        }

        self.presentingViewController?.dismiss(animated: true, completion: {
            self.tokenObserver?.onNext((token: token, login: login, vendor: vendor, expDate: expDate))
        })
        return false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.hideProgressView()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.showProgressView()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.hideProgressView()
    }

    // MARK: Наблюдение за прогрессом WKWebView и работа с UI прогресса

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
        }
    }

    func addObserversAndDelegates() {
        webView.addObserver(self,
                            forKeyPath: #keyPath(WKWebView.estimatedProgress),
                            options: .new,
                            context: nil)
        self.webView.navigationDelegate = self
    }

    func removeObserversAndDelegates() {
        webView.navigationDelegate = nil
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }

    let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.progressTintColor = Colors.mainTheme
        view.trackTintColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    func showProgressView() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.progressView.alpha = 1
        }, completion: nil)
    }

    func hideProgressView() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            self.progressView.alpha = 0
        }, completion: nil)
    }
}
