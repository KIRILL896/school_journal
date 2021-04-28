//
//  SchoolsSearchViewModel.swift
//  scool_journal
//
//  Created by отмеченные on 13/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

typealias SchoolSection = SectionModel<String, SchoolSearchItem>

protocol SchoolsSearchViewModelProtocol {

    var loading: Driver<Bool>! { get }
    var errorOccured: Driver<String>! { get }
    var showInfoView: Driver<Bool>! { get }

    var schoolPicked: Driver<SchoolSearchItem?>! { get }

    var sections: Driver<[SchoolSection]>! { get }

    func configure(bindings: SchoolsSearchViewModelBindings)
}

struct SchoolsSearchViewModelBindings {

    let queryChanged: Driver<String>
    let itemSelected: Driver<Int>
}

class SchoolsSearchViewModel: BaseViewModel, SchoolsSearchViewModelProtocol {

    typealias Dependency = HasGlobalService

    var loading: Driver<Bool>!
    var errorOccured: Driver<String>!
    var sections: Driver<[SchoolSection]>!
    var schoolPicked: Driver<SchoolSearchItem?>!
    private let schoolSubject = PublishSubject<SchoolSearchItem?>()

    var showInfoView: Driver<Bool>!

    var dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
        schoolPicked = schoolSubject.asDriverOnErrorJustComplete()
    }

    func configure(bindings: SchoolsSearchViewModelBindings) {
        let deps = dependency
        let activityTracker = ActivityIndicator()
        let request = bindings.queryChanged
            .distinctUntilChanged()
            .debounce(RxTimeInterval.milliseconds(500))
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler.defaultScheduler)
            .flatMapLatest { query -> Observable<[SchoolSearchItem]> in
                let queryTrimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if queryTrimmed.count < 2 {
                    return Observable<[SchoolSearchItem]>.create { observer in
                        observer.onNext([SchoolSearchItem]())
                        observer.onCompleted()
                        return Disposables.create()
                    }
                }

                return deps.globalService.searchSchools(with: queryTrimmed)
                    .asObservable()
                    .trackActivity(activityTracker)
                    .catchErrorJustReturn([])

            }.share()

        sections = request.asDriver(onErrorJustReturn: []).map({
            return [SchoolSection(model: "", items: $0)]
        })

        bindings.itemSelected.withLatestFrom(request.asDriverOnErrorJustComplete(), resultSelector: { index, array in
            return array[index]
        }).drive(schoolSubject).disposed(by: disposeBag)

        showInfoView = request
            .asDriver(onErrorJustReturn: [])
            .map({ $0.isEmpty })
            .asDriver()
        loading = activityTracker.asDriver()
    }
}
