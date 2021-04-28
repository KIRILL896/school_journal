//
//  MarksViewModel.swift
//  scool_journal
//
//  Created by отмеченные on 16/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift
import RxCocoa
import RxDataSources

struct DiaryCellModel {

    enum CellType {
        case info
        case empty
        case holiday
        case vacation
        case ad
    }
    var type: DiaryCellModel.CellType
    var holidayName: String?
    var item: Diary.Item
}

typealias DiarySection = SectionModel<Diary, DiaryCellModel>

protocol DiaryViewModelProtocol {

    var loading: Driver<Bool>! { get }
    var errorOccured: Driver<String>! { get }
    var wrongInput: Driver<Void>! { get }
    var studentName: Driver<(name: String?, canChoose: Bool)>! { get }
    var periodName: Driver<String?>! { get }
    var sections: Driver<[DiarySection]>! { get }

    func configure(bindings: DiaryViewModelBindings)
}

struct DiaryViewModelBindings {

    let didTriggerRefreshControll: Driver<Void>
    let didPressPickStudent: Driver<Void>
    let didPressPickPeriod: Driver<Void>
    let expandedItems: Driver<[Diary.Item]>

    let didTapAd: Driver<String>
    let didLoadAd: Driver<String>
}

class DiaryViewModel: BaseViewModel, DiaryViewModelProtocol {
    typealias Dependency = HasUserStorage & HasDiaryService & HasPeriodsStorage & HasAdService

    var loading: Driver<Bool>!
    var errorOccured: Driver<String>!
    var sections: Driver<[DiarySection]>!
    var wrongInput: Driver<Void>!
    var studentName: Driver<(name: String?, canChoose: Bool)>!
    var periodName: Driver<String?>!
    var wantsToOpenSchoolPicker: Driver<Void>!

    private var currentStudent = BehaviorRelay<Student?>(value: nil)
    private var currentWeek = BehaviorRelay<Week?>(value: nil)

    var dependencies: Dependency

    init(dependencies: Dependency) {
        self.dependencies = dependencies
    }

    func configure(bindings: DiaryViewModelBindings) {
        let deps = dependencies
        let user = deps.userStorage.currentUser.share()

        let activityTracker = ActivityIndicator()
        let errorTracker = ErrorTracker()

        user.map({ user -> Student? in
        let currentPrefferedStudentName = deps.userStorage.perfferedStudentName
            if let preffered = user.students.filter({ $0.name == currentPrefferedStudentName }).first {
                return preffered
            }
            return user.students.first
        })
        .take(1)
        .bind(to: currentStudent)
        .disposed(by: disposeBag)

        let weeks = currentStudent
            .compactMap({ $0 })
            .flatMap({ deps.periodsStorage.periods(for: $0.name) })
            .map({ periods in
                periods.map({ $0.weeks }).flatMap({ $0 })
            })

        weeks
            .map({ return $0.matchesCurrentDate() ?? $0.last })
            .bind(to: currentWeek)
            .disposed(by: disposeBag)

        let studentAndUser = Observable.combineLatest(user, currentStudent).asDriverOnErrorJustComplete()
        _ = bindings.didPressPickStudent.withLatestFrom(studentAndUser).drive(onNext: { [unowned self] tuple in
            let user = tuple.0
            guard let student = tuple.1 else { return }

            let index = user.students.firstIndex(where: ({ $0.name == student.name })) ?? 0
            self.openStudentPicker(students: user.students, selectedIndex: index)
        }).disposed(by: disposeBag)

        let weekPickerAndWeeks = Observable.combineLatest(weeks, currentWeek).asDriverOnErrorJustComplete()

        _ = bindings.didPressPickPeriod.withLatestFrom(weekPickerAndWeeks).drive(onNext: { [unowned self] tuple in
            let weeks = tuple.0
            guard let week = tuple.1 else { return }

            let index = weeks.firstIndex(where: ({ $0.title == week.title })) ?? weeks.count - 1
            self.openWeekPicker(weeks: weeks, selectedIndex: index)
        }).disposed(by: disposeBag)

        let studObservable = currentStudent.asObservable()
        let currentWeekObservable = currentWeek.asObservable()

        let currentStudAndWeek = Observable
            .combineLatest(studObservable, currentWeekObservable)
            .share(replay: 1, scope: .whileConnected)

        currentStudAndWeek.subscribe(onNext: { tuple in
            let student = tuple.0
            let week = tuple.1
            CrashlyticsHelper.setCurrent(student: student, week: week, module: "Diary")
        }).disposed(by: disposeBag)

        let loadTrigger = Observable
            .merge(
                studObservable.mapToVoid(),
                currentWeek.mapToVoid().skip(1),
                bindings.didTriggerRefreshControll.asObservable()
            )
            .share(replay: 1, scope: .forever)

        let request = loadTrigger
            .debounce(.milliseconds(150), scheduler: MainScheduler.instance)
            .withLatestFrom(currentStudAndWeek)
            .flatMap { tuple -> Observable<[Diary]> in
                guard let student = tuple.0, let week = tuple.1 else {
                    return Observable<[Diary]>
                        .just([])
                        .trackActivity(activityTracker)
                }
                return deps.diaryService
                    .diary(for: student.name, week: week, rings: true)
                    .asObservable()
                    .trackError(errorTracker)
                    .catchErrorJustReturn([])
            }.share()

        errorOccured = errorTracker.asDriver().map({ $0.localizedDescription })

        let adRequest = loadTrigger
            .withLatestFrom(user)
            .flatMapLatest({ usr -> Observable<[String]> in
                if usr.roles.isEmpty { return .empty() }
                var role = usr.roles[0]
                if usr.roles.contains(.parent) {
                    role = .parent
                }
                return deps.adService
                    .getAdvertising(role: role, city: usr.city, region: usr.region, parallel: "all")
                    .asObservable()
                    .trackActivity(activityTracker)
                    .catchErrorJustReturn([])
        }).share()

        sections = request.asDriver(onErrorJustReturn: [])
            .withLatestFrom(adRequest.asDriver(onErrorJustReturn: [])) { array, adRules -> [DiarySection]  in
            var sectionsArray = [DiarySection]()

            let sortedDiary = array.sorted { $0.date < $1.date }

            if sortedDiary.isEmpty {
                var diary = Diary()
                diary.id = EmptySectionModelName
                let dcm = DiaryCellModel(type: .empty, item: Diary.Item())
                sectionsArray.append(
                    DiarySection(model: diary, items: [dcm])
                )
            } else {
                for (_, diary) in sortedDiary.enumerated() {
                    if diary.isHoliday {
                        let dcm = DiaryCellModel(type: .holiday, holidayName: diary.holidayName, item: Diary.Item())
                        sectionsArray.append(
                            DiarySection(model: diary, items: [dcm])
                        )
                    } else if diary.isVacation {
                        let dcm = DiaryCellModel(type: .vacation, holidayName: L10n.Common.vacation, item: Diary.Item())
                        sectionsArray.append(
                            DiarySection(model: diary, items: [dcm])
                        )
                    } else {
                        if diary.items.isEmpty && diary.itemsExtday.isEmpty { continue }
                        var diaryItems = [Diary.Item]()
                        diaryItems.append(contentsOf: diary.items)
                        diaryItems.append(contentsOf: diary.itemsExtday)
                        let sortedItems = diaryItems.sorted { $0.lessonInfo.sort < $1.lessonInfo.sort }
                        var itemsForSection = [DiaryCellModel]()
                        for (_, item) in sortedItems.enumerated() {
                            itemsForSection.append(DiaryCellModel(type: .info, item: item))
                        }
                        sectionsArray.append(
                            DiarySection(model: diary, items: itemsForSection)
                        )
                    }
                }
            }

            if Constants.inScreenshotMode { // Disabling ads on screenshots
                return sectionsArray
            }

            if adRules.contains("DIARY_TOP") {
                var diary = Diary()
                diary.id = AdSectionModelName + UUID().uuidString
                var item = Diary.Item()
                item.adBlockId = Constants.topDiaryAdBlockId
                let dcm = DiaryCellModel(type: .ad, item: item)
                sectionsArray.insert(DiarySection(model: diary, items: [dcm]), at: 0)
            }

            if adRules.contains("DIARY_TODAY") {
                if !sectionsArray.isEmpty {
                    if let index = sectionsArray.map({ $0.model }).firstIndex(where: { $0.date.isSameDay(otherDate: Date()) }) {
                        var diary = Diary()
                        diary.id = AdSectionModelName + UUID().uuidString
                        var item = Diary.Item()
                        item.adBlockId = Constants.todayDiaryAdBlockId
                        let dcm = DiaryCellModel(type: .ad, item: item)
                        sectionsArray.insert(DiarySection(model: diary, items: [dcm]), at: index + 1)
                    }
                }
            }

            return sectionsArray
            }

//        bindings.didLoadAd.asObservable().flatMap({ id in
//                deps.adService
//                    .setAdvertisingSeen(id: id)
//                    .catchErrorJustReturn(())
//            })
//            .subscribe()
//            .disposed(by: disposeBag)
//        bindings.didTapAd.asObservable().flatMap({ id in
//            deps.adService
//                .setAdvertisingClick(id: id)
//                .catchErrorJustReturn(())
//            })
//            .subscribe()
//            .disposed(by: disposeBag)
        let canChooseStudent = user.map({ $0.students.count > 1 }).asDriverOnErrorJustComplete()

        studentName = currentStudent
            .compactMap({ $0 })
            .withLatestFrom(canChooseStudent, resultSelector: { student, canChoose in
                return (name: student.firstnameLabel, canChoose: canChoose)
            })
            .asDriver(onErrorJustReturn: (name: "", canChoose: false))

        periodName = currentWeek.compactMap({ $0 })
            .map({ $0.stringRepresentationForViews })
            .asDriver(onErrorJustReturn: "")

        loading = activityTracker.asDriver()
    }

    func openStudentPicker(students: [Student], selectedIndex: Int) {
        if students.count < 2 { return }
        let names = students.map({ $0.firstnameLabel })
        let picker = PickerView.open(for: names, selectedIndex: selectedIndex)
        picker.itemPicked.subscribe(onNext: { [weak self] index in
            if let index = index, index != selectedIndex {
                self?.currentStudent.accept(students[index])
                self?.dependencies.userStorage.setPrefferedStudentName(students[index].name)
            }
            picker.hide()
        }).disposed(by: picker.disposeBag)
    }

    func openWeekPicker(weeks: [Week], selectedIndex: Int) {
        let names = weeks.map({ $0.stringRepresentationForViews })
        let picker = PickerView.open(for: names, selectedIndex: selectedIndex)
        picker.itemPicked.subscribe(onNext: { [weak self] index in
            if let index = index, index != selectedIndex {
                self?.currentWeek.accept(weeks[index])
            }
            picker.hide()
        }).disposed(by: picker.disposeBag)
    }
}
