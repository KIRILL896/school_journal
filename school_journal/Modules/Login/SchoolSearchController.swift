//
//  SchoolSearchController.swift
//  scool_journal
//
//  Created by отмеченные on 13/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import RxKeyboard

class SchoolSearchController: UIViewController, UISearchControllerDelegate {

    let disposeBag = DisposeBag()

    var dataSource: RxTableViewSectionedReloadDataSource<SchoolSection>!

    var viewModel: SchoolsSearchViewModelProtocol!

    let querySubject = PublishSubject<String>()

    @IBOutlet weak var lbInfo: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var vInfoContainer: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupViews()
        setupViewModel()
        setupBindings()
        setupSearch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.searchController.isActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.searchController.searchBar.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.searchController.isActive = false
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewWillDisappear(animated)
    }

    func setupViews() {
        title = L10n.SchoolSearch.screenTitle
        lbInfo.text = L10n.SchoolSearch.screenInfoText
    }

    func setupViewModel() {
        let queryChanged = searchController.searchBar.rx.text.orEmpty.asDriver().debug("queryChanged")
        let itemSelected = tableView.rx.itemSelected.map({ $0.row }).asDriverOnErrorJustComplete()
        let bindings = SchoolsSearchViewModelBindings(queryChanged: queryChanged,
                                                      itemSelected: itemSelected)
        viewModel.configure(bindings: bindings)
    }

    func setupBindings() {
        let dataSource = RxTableViewSectionedReloadDataSource<SchoolSection>(configureCell: { _, tv, _, item in
            let cell = tv.dequeueReusableCell(withIdentifier: SearchSchoolCell.reuseIdentifier) as! SearchSchoolCell
            cell.lbName.text = item.title
            cell.lbLocation.text = item.label
            cell.lbDomain.text = item.value
            return cell
        })
        self.dataSource = dataSource
        tableView.rx.itemSelected.asDriver().drive(onNext: { [unowned self] indexPath in
            self.tableView.deselectRow(at: indexPath, animated: true)
        }).disposed(by: disposeBag)
        viewModel.sections.drive(tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)

        viewModel.loading.drive(onNext: { [weak self] loading in
            if loading {
                self?.showActivity()
            } else {
                self?.hideActivity()
            }
        }).disposed(by: disposeBag)

        viewModel.showInfoView.drive(onNext: { [weak self] show in
            if show {
                self?.showInfoView()
            } else {
                self?.hideInfoView()
            }
        }).disposed(by: disposeBag)
        RxKeyboard.instance.visibleHeight.drive(onNext: {[weak self] keyboardVisibleHeight in
            if keyboardVisibleHeight == 0 {
                self?.tableView.contentInset.bottom = 0
            } else {
                self?.tableView.contentInset.bottom = keyboardVisibleHeight
            }
        }).disposed(by: disposeBag)
    }

    func hideInfoView() {
        UIView.animate(withDuration: 0.3) {
            self.vInfoContainer.alpha = 0
        }
    }

    func showInfoView() {
        self.vInfoContainer.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.vInfoContainer.alpha = 1
        }
    }

    func showActivity() {
        UIView.animate(withDuration: 0.3) {
            self.activityIndicator.alpha = 1
            self.activityIndicator.startAnimating()
        }
    }

    func hideActivity() {
        UIView.animate(withDuration: 0.3) {
            self.activityIndicator.alpha = 0
            self.activityIndicator.stopAnimating()
        }
    }

    func setupTableView() {
        tableView.register(LoadingCell.nib, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        tableView.register(EmptyCell.nib, forCellReuseIdentifier: EmptyCell.reuseIdentifier)
        tableView.register(SearchSchoolCell.nib, forCellReuseIdentifier: SearchSchoolCell.reuseIdentifier)
        tableView.rowHeight = 80 // UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.tableFooterView = UIView()
    }

    func setupSearch() {
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        self.definesPresentationContext = true
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = L10n.Common.search
        searchController.searchBar.setShowsCancelButton(false, animated: false)
        if #available(iOS 13.0, *) {
            searchController.automaticallyShowsCancelButton = false
        } else {
            searchController.searchBar.setShowsCancelButton(false, animated: false)
        }

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }
}

extension SchoolSearchController: UISearchBarDelegate {

}
