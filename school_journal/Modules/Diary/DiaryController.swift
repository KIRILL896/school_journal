//
//  DiaryController.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//
import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxGesture
import YandexMobileAds

class DiaryController: ViewController {

    let disposeBag = DisposeBag()

    let expandedItems = BehaviorRelay<[Diary.Item]>(value: [Diary.Item]())

    var viewModel: DiaryViewModelProtocol!
    var dataSource: RxTableViewSectionedReloadDataSource<DiarySection>!

    private let refreshControl = UIRefreshControl()

    @IBOutlet weak var cnstPickerDividerHeight: NSLayoutConstraint!
    @IBOutlet weak var vPickerContainer: UIView!
    @IBOutlet weak var vPickerSeparator: UIView!
    @IBOutlet weak var btnStudent: EjPickerButton!
    @IBOutlet weak var btnPeriod: EjPickerButton!
    @IBOutlet weak var vButtonsContainer: EjPickerButtonContainer!
    @IBOutlet weak var tableView: UITableView!

    private let didLoadAdSubject = PublishSubject<String>()
    private let didTapAdSubject = PublishSubject<String>()

    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = L10n.Diary.screenTitle
        addSideMenuButton()
        setupViews()
        setupTableView()
        setupRefreshControll()
        setupViewModel()
        setupBindings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationController?.navigationBar.hideBottomHairline()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.navigationBar.showBottomHairline()
    }

    func setupViews() {
        vPickerContainer.backgroundColor = Colors.defaultSystemBarsBackground
        vPickerSeparator.backgroundColor = Colors.mainTheme
        // vButtonsContainer is stylized in ButtonsContainer class
        // btnStudent and btnPeriod are stylized in PickerButton
    }

    func setupTableView() {
        tableView.register(LoadingCell.nib, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(EmptyCell.nib, forCellReuseIdentifier: EmptyCell.reuseIdentifier)
        tableView.register(DiaryLessonCell.nib, forCellReuseIdentifier: DiaryLessonCell.reuseIdentifier)
        tableView.register(VacationCell.nib, forCellReuseIdentifier: VacationCell.reuseIdentifier)
        tableView.register(AdCell.self, forCellReuseIdentifier: "AdCell")
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
        tableView.canCancelContentTouches = false
        tableView.rowHeight = UITableView.automaticDimension
    }

    func setupRefreshControll() {
        guard refreshControl.superview == nil else { return }

        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
    }

    func setupViewModel() {
        let didTriggerRefreshControll = refreshControl.rx.controlEvent(.valueChanged)
            .mapToVoid()
            .asDriverOnErrorJustComplete()
        let didPressPickStudent = btnStudent.rx.tap.mapToVoid().asDriverOnErrorJustComplete()
        let didPressPickPeriod = btnPeriod.rx.tap.mapToVoid().asDriverOnErrorJustComplete()
        let bindings = DiaryViewModelBindings(
            didTriggerRefreshControll: didTriggerRefreshControll,
            didPressPickStudent: didPressPickStudent,
            didPressPickPeriod: didPressPickPeriod,
            expandedItems: expandedItems.asDriver(),
            didTapAd: didTapAdSubject.asDriverOnErrorJustComplete(),
            didLoadAd: didLoadAdSubject.asDriverOnErrorJustComplete()
        )
        viewModel.configure(bindings: bindings)
    }

    func setupBindings() {
        let dataSource = RxTableViewSectionedReloadDataSource<DiarySection>(configureCell: { [weak self] _, tv, _, section -> UITableViewCell in
            let item = section.item
            switch section.type {
            case .empty:
                let cell = tv.dequeueReusableCell(withIdentifier: EmptyCell.reuseIdentifier) as! EmptyCell
                cell.hideSeparator()
                return cell
            case .info:
                let cell = tv.dequeueReusableCell(withIdentifier: DiaryLessonCell.reuseIdentifier) as! DiaryLessonCell
                cell.selectionStyle = .none
                cell.configure(for: item)
                cell.showSeparator(32)
                return cell
            case .holiday:
                let cell = tv.dequeueReusableCell(withIdentifier: VacationCell.reuseIdentifier) as! VacationCell
                cell.lbTitle.text = section.holidayName ?? L10n.Common.vacation
                cell.hideSeparator()
                return cell
            case .vacation:
                let cell = tv.dequeueReusableCell(withIdentifier: VacationCell.reuseIdentifier) as! VacationCell
                cell.lbTitle.text = L10n.Common.vacation
                cell.hideSeparator()
                return cell
            case .ad:
                let cell = tv.dequeueReusableCell(withIdentifier: "AdCell") as! AdCell
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if self?.isLoading == false {
                        cell.setup(for: item.adBlockId, dataId: item.id)
                    }
                }
                cell.hideSeparator()
                if let `self` = self {
                    cell.didTapAd.drive(self.didTapAdSubject).disposed(by: cell.disposeBag)
                    cell.didLoadAd.drive(self.didLoadAdSubject).disposed(by: cell.disposeBag)
                }
                return cell
            }
        })
//        dataSource.animationConfiguration = AnimationConfiguration(insertAnimation: .fade, reloadAnimation: .left, deleteAnimation: .fade)
        self.dataSource = dataSource
//        tableView.rx.itemSelected.asDriver().drive(onNext: { [unowned self] indexPath in
//            let cellModel = dataSource.sectionModels[indexPath.section].items[indexPath.row]
//            let item = cellModel.item
//            if case .title = cellModel.type {
//                var currentSelectedItems = self.expandedItems.value
//                if let index = currentSelectedItems.firstIndex(where: {$0.id == item.id}) {
//                    _ = currentSelectedItems.remove(at: index)
//                    self.expandedItems.accept(currentSelectedItems)
//                } else {
//                    currentSelectedItems.append(item)
//                    self.expandedItems.accept(currentSelectedItems)
//                }
//            }
//            self.tableView.deselectRow(at: indexPath, animated: true)
//        }).disposed(by: disposeBag)
        viewModel.sections.drive(tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        tableView.rx.setDelegate(self).disposed(by: disposeBag)

        viewModel.loading.drive(onNext: { [weak self] bool in
            self?.isLoading = bool
            if bool {
                self?.tableView.scrollToTop()
                if self?.refreshControl.isRefreshing == false {
                    self?.showProgress()
                }
            } else {
                self?.hideProgressView()
                if self?.refreshControl.isRefreshing == true {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                        self?.refreshControl.endRefreshing()
                    })
                }
            }
        }).disposed(by: disposeBag)

        viewModel.studentName.drive(onNext: { [weak self] tuple in
            let name = tuple.0
            let canChoose = tuple.1
            let attrs = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
                NSAttributedString.Key.foregroundColor: Colors.mainTheme
            ]
            let attrStr = NSAttributedString.string(
                name ?? "",
                with: attrs,
                image: canChoose ? Assets.Images.icChevronDownRed.image.imageWithColor(color: Colors.mainTheme) : nil,
                offsetY: 1.0
            )
            self?.btnStudent.setAttributedTitle(attrStr, for: .normal)
            self?.btnStudent.canChoose = canChoose
        }).disposed(by: disposeBag)

        viewModel.periodName.drive(onNext: { [weak self] name in
            let attrs = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
                NSAttributedString.Key.foregroundColor: Colors.mainTheme
            ]
            let attrStr = NSAttributedString.string(
                name ?? "",
                with: attrs,
                image: Assets.Images.icChevronDownRed.image.imageWithColor(color: Colors.mainTheme),
                offsetY: 1.0
            )
            self?.btnPeriod.setAttributedTitle(attrStr, for: .normal)
        }).disposed(by: disposeBag)

        viewModel.errorOccured.drive(onNext: { [weak self] error in
            self?.showErrorToast(with: error)
        }).disposed(by: disposeBag)

        NotificationCenter.default.rx
            .notification(UIDevice.orientationDidChangeNotification).asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.handleDeviceOrientationChanged()
        }).disposed(by: disposeBag)
    }

    func handleDeviceOrientationChanged() {
        let visibleCells = tableView.visibleCells
        for cell in visibleCells {
            if let adCell = cell as? AdCell {
                adCell.reloadOnforCurrentOrientation()
            }
        }
    }
}

extension DiaryController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = dataSource.sectionModels[indexPath.section].items[indexPath.row]
        switch item.type {
        case .info:
            return 120
        case .holiday,
             .vacation,
             .empty:
            return CGFloat(Constants.listInfoHeight)
        case .ad:
            return CGFloat(Constants.diaryAdSize.height + 32.0)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let item = dataSource.sectionModels[section].model
        if item.id == EmptySectionModelName { return 0 }
        if item.id.contains(AdSectionModelName) { return 0 }
        return CGFloat(Constants.listHeaderHeight)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let model = dataSource.sectionModels[section].model
        if model.id == LoadingSectionModelName { return nil }
        let header = SimpleSectionHeader.loadFromNib()
        header.lbTitle.text = model.date.stringRepresentationWithDay
        header.lbMark.isHidden = true
        header.lbInfo.isHidden = true
        return header
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.000_01
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        TooltipManager.shared().dismiss()
    }
}
