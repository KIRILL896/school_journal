//
//  AdCell.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import UIKit
import YandexMobileAds
import RxSwift
import RxCocoa

class AdCell: UITableViewCell, YMANativeAdLoaderDelegate {

    var disposeBag = DisposeBag()

    var loader: YMANativeAdLoader!

    var currentAdId: String?
    var currentDataPortionId: String?

    private let didLoadAdSubject = PublishSubject<String>()
    private let didTapAdSubject = PublishSubject<String>()

    var didLoadAd: Driver<String> {
        return didLoadAdSubject.asDriverOnErrorJustComplete()
    }

    var didTapAd: Driver<String> {
        return didLoadAdSubject.asDriverOnErrorJustComplete()
    }

    lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.background
        return view
    }()

    lazy var bottomDivider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.adsDivider
        return view
    }()

    lazy var topDivider: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.adsDivider
        return view
    }()

    var adView: YMANativeBannerView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag = DisposeBag()
        if loader != nil {
            loader.delegate = nil
        }
    }

    func nativeAdLoader(_ loader: YMANativeAdLoader!, didFailLoadingWithError error: Error) {
        print(error)
    }

    func nativeAdLoader(_ loader: YMANativeAdLoader!, didLoad ad: YMANativeContentAd) {
        adView?.ad = ad
    }

    func setupViews() {
        backgroundColor = Colors.adsBackground
        contentView.addSubview(container)
        container.fillSuperview()
        container.heightAnchor
            .constraint(equalToConstant: Constants.diaryAdSize.height + 32.0).isActive = true
        container.addSubview(bottomDivider)
        bottomDivider.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        bottomDivider.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
        bottomDivider.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
        bottomDivider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        container.addSubview(topDivider)
        topDivider.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        topDivider.leftAnchor.constraint(equalTo: container.leftAnchor).isActive = true
        topDivider.rightAnchor.constraint(equalTo: container.rightAnchor).isActive = true
        topDivider.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    }

    func setup(for adId: String, dataId: String?, force: Bool = false) {
        if currentDataPortionId == dataId && !force { return }
        var adWidth = UIScreen.main.bounds.width
        if #available(iOS 11.0, *) {
            if let window = UIApplication.shared.delegate?.window {
                let safeAreaLeftInset = window!.safeAreaInsets.left
                let safeAreaRightInset = window!.safeAreaInsets.right
                adWidth = UIScreen.main.bounds.width - safeAreaLeftInset - safeAreaRightInset
            }
        }
        addMediaView(with: adWidth)
        let adSize = CGSize(width: adWidth, height: Constants.diaryAdSize.height)
        let configuration = YMANativeAdLoaderConfiguration(
            blockID: adId, imageSizes: [adSize], loadImagesAutomatically: true)
        loader = YMANativeAdLoader(configuration: configuration)
        loader.delegate = self
        loader.loadAd(with: nil)
        currentAdId = adId
        currentDataPortionId = dataId
    }

    func reloadOnforCurrentOrientation() {
        guard let caid = currentAdId else {
            return
        }
        setup(for: caid, dataId: currentDataPortionId, force: true)
    }

    func addMediaView(with width: CGFloat) {
        if let av = adView {
            av.removeFromSuperview()
        }
        let view = YMANativeBannerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        container.addSubview(view)
        view.heightAnchor.constraint(equalToConstant: Constants.diaryAdSize.height).isActive = true
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        view.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
        view.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        self.adView = view
    }
}
