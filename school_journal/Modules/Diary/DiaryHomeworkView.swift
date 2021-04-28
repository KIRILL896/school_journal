//
//  DiaryHomeworkView.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift
import RxGesture
import UIKit

class DiaryHomeworkView: UIView, HasNib {
    var disposeBag = DisposeBag()

    @IBOutlet weak var vTask: UIView!
    @IBOutlet weak var ivIcon: UIImageView!
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var svFiles: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()

        lbTitle.text = Constants.emptyLabel
        lbTitle.textColor = Colors.hometask
        ivIcon.image = ivIcon.image?.fillAlpha(with: Colors.hometask)
    }

    func configure(with homework: Homework) {
        lbTitle.text = homework.value
        vTask.rx.tapGesture().when(.recognized).subscribe(onNext: { _ in
            weak var viewController = self.vTask.getViewController()
            viewController?.openHometask(string: homework.value)
            self.vTask.animateTap()
        }).disposed(by: disposeBag)

        svFiles.isHidden = homework.files.isEmpty && homework.resources.isEmpty
        svFiles.removeAllArrangedSubviews()

        for file in homework.files {
            let flView = CommonFileView.loadFromNib()
            flView.translatesAutoresizingMaskIntoConstraints = false
            flView.lbTitle.text = file.name
            svFiles.addArrangedSubview(flView)
            flView.rx.tapGesture().when(.recognized).subscribe(onNext: { _ in
                weak var viewController = flView.getViewController()
                viewController?.openFile(file)
                flView.animateTap()
            }).disposed(by: disposeBag)
        }

        for resource in homework.resources {
            let resView = CommonFileView.loadFromNib()
            resView.translatesAutoresizingMaskIntoConstraints = false
            resView.lbTitle.text = resource.name
            svFiles.addArrangedSubview(resView)
            resView.rx.tapGesture().when(.recognized).subscribe(onNext: { _ in
                weak var viewController = resView.getViewController()
                viewController?.openResource(resource)
                resView.animateTap()
            }).disposed(by: disposeBag)
        }
    }
}
