//
//  DiaryLessonCell.swift
//  scool_journal
//
//  Created by отмеченные on 17/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift
import RxGesture
import UIKit

class DiaryLessonCell: UITableViewCell, HasNib, Reusable {
    var disposeBag = DisposeBag()

    @IBOutlet weak var lbNum: UILabel!
    @IBOutlet weak var lbTitle: EjLessonLabel!
    @IBOutlet weak var lbTime: UILabel!
    @IBOutlet weak var svTopic: UIStackView!
    @IBOutlet weak var svMarks: UIStackView!
    @IBOutlet weak var cnstMarksHeight: NSLayoutConstraint!
    @IBOutlet weak var cnstMarksWidth: NSLayoutConstraint!
    @IBOutlet weak var svHomeWork: UIStackView!

    override func prepareForReuse() {
        super.prepareForReuse()

        disposeBag = DisposeBag()

        lbNum.text = ""
        lbTime.text = Constants.emptyLabel
        lbTitle.setText(lessonName: Constants.emptyLabel, groupName: "")

        svMarks.removeAllArrangedSubviews()
        svMarks.isHidden = true
        cnstMarksHeight.constant = 0
        cnstMarksWidth.constant = 0

        svTopic.removeAllArrangedSubviews()
        svTopic.isHidden = true

        svHomeWork.removeAllArrangedSubviews()
        svHomeWork.isHidden = true
    }

    func configure(for item: Diary.Item) {
        lbNum.text = item.lessonInfo.num

        // Time
        let timeLabel = item.lessonInfo.timeLabel
        if timeLabel.isEmpty {
            lbTime.text = Constants.emptyLabel
            lbTime.isHidden = true
        } else {
            lbTime.text = timeLabel
            lbTime.isHidden = false
        }

        // Marks
        svMarks.removeAllArrangedSubviews()
        if item.marks.isEmpty {
            svMarks.isHidden = true
            cnstMarksHeight.constant = 0
            cnstMarksWidth.constant = 0
        } else {
            for mark in item.marks {
                let markCell = CommonMarkView.loadFromNib()
                markCell.configure(for: mark, isHiddenDate: true)
                markCell.widthAnchor.constraint(equalToConstant: CGFloat(Constants.markWidth)).isActive = true
                svMarks.addArrangedSubview(markCell)
            }

            let marksCount = Int(item.marks.count)
            let width: Int = Int(Constants.markWidth) * marksCount + Int(Constants.markSpacing) * (marksCount - 1)

            svMarks.isHidden = false
            cnstMarksHeight.constant = CGFloat(Constants.markHeight)
            cnstMarksWidth.constant = CGFloat(width)
        }

        // Title
        lbTitle.configure(with: item.lessonInfo)

        svTopic.removeAllArrangedSubviews()
        svHomeWork.removeAllArrangedSubviews()

        // Topic
        if item.lessonInfo.topic.count > 0 {
            let subjectView = DiarySubjectView.loadFromNib()
            subjectView.lbTitle.text = L10n.Diary.lessonSubject(item.lessonInfo.topic)
            svTopic.addArrangedSubview(subjectView)
            svTopic.isHidden = false
        } else {
            svTopic.isHidden = true
        }

        // Hometasks
        if item.homework.count == 0 {
            svHomeWork.isHidden = true
        } else {
            let sortedHomework = item.homework.sorted(by: { $0.id < $1.id })
            for hw in sortedHomework {
                let hwView = DiaryHomeworkView.loadFromNib()
                hwView.configure(with: hw)
                // hwView.translatesAutoresizingMaskIntoConstraints = false
                svHomeWork.addArrangedSubview(hwView)
            }
            svHomeWork.isHidden = false
        }
    }

}
