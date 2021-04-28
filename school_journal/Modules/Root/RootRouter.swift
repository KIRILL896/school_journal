//
//  RootRouter.swift
//  scool_journal
//
//  Created by отмеченные on 01/02/2021.
//  Copyright © 2021 отмеченные. All rights reserved.
//

import RxSwift
import RxCocoa
import LGSideMenuController

class RootRouter: BaseRouter {

    let window: UIWindow
    var dependencies: AppDependency
    var viewModel: RootViewModel
    var rootViewController: UIViewController?
    weak var tabsController: TabsController?
    weak var sideMenyController: SideMenuController?

    var logoutObserver: AnyObserver<Void>?
    private var logoutSubject = PublishSubject<Void>()

    let updatesTabTag = 1
    let diarytabTag = 2
    let announcementsTabTag = 3
    let messagesTabTag = 4

    init(
        window: UIWindow,
        sourceViewController: UIViewController? = nil,
        dependencies: AppDependency,
        logoutObserver: AnyObserver<Void>?) {

        self.dependencies = dependencies
        self.window = window
        self.logoutObserver = logoutObserver
        viewModel = RootViewModel(dependencies: dependencies, logoutObserver: logoutObserver)
        super.init(sourceViewController: sourceViewController)
    }

    func start() {
        let sideMenuVC = SideMenuController.instanceFromStoryboard()
        let sideMenuVM = SideMenuViewModel(dependencies: dependencies)
        sideMenuVC.viewModel = sideMenuVM
        sideMenuVM.menuItemSelected.drive(onNext: { [weak self] section in
            self?.sideMenuItemSelected(section)
        }).disposed(by: sideMenuVM.disposeBag)
        sideMenuVM.logoutPressed.drive(onNext: { [weak self] in
            self?.logoutSubject.onNext(())
        }).disposed(by: sideMenuVM.disposeBag)
        self.sideMenyController = sideMenuVC

        let tabsController = TabsController()
        self.tabsController = tabsController

        let rootVC = LGSideMenuController(
            rootViewController: tabsController, leftViewController: sideMenuVC, rightViewController: nil)

        var width = 280.0
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            width = 350.0
        }
        rootVC.leftViewWidth = CGFloat(width)
        rootVC.leftViewPresentationStyle = .slideAbove
        rootVC.rootViewCoverBlurEffectForLeftView = UIBlurEffect(style: .light)
        rootVC.isLeftViewStatusBarHidden = true
        rootVC.leftViewLayerShadowColor = UIColor.clear
        rootVC.leftViewCoverColor = Colors.mainTheme
        self.window.setRootViewController(rootVC)
        self.rootViewController = rootVC

        let bindings = RootViewModelBindings(logout: logoutSubject.asDriverOnErrorJustComplete())
        viewModel.configure(bindings: bindings)

        setupViewModel()
        if Constants.inScreenshotMode { return }
        registerForPushNotifications()
    }

    func setupViewModel() {
        viewModel.items.drive(onNext: { [weak self] items in
            self?.setTabs(with: items)
        }).disposed(by: disposeBag)

        viewModel.didReceivePush.drive(onNext: { [weak self] push in
            self?.rootViewController?
                .showPushNotification(title: push.title, body: push.body, onTapAction: { [weak self] in
                    self?.swithcToDiary()
                })
        }).disposed(by: disposeBag)

    }

    func swithcToDiary() {
        openTab(for: .diary)
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current() // 1
        .requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Push permission granted: \(granted)")
            guard granted else { return }

            self?.getNotificationSettings()
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func setTabs(with items: [MenuItem]) {
        var viewControllers = [UIViewController]()
        for item in items {
            switch item.section {
            case .updates:
                let vc = UpdatesController.instanceFromStoryboard()
                let vm = UpdatesViewModel(dependencies: dependencies)
                vc.viewModel = vm
                let nvc = UINavigationController(rootViewController: vc)
                if #available(iOS 11.0, *) {
                    nvc.navigationBar.prefersLargeTitles = true
                }
                let tabbarItem = UITabBarItem(title: "  ", image: Assets.Images.icTabUpdates.image, tag: updatesTabTag)
//                tabbarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 50)
                tabbarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
                vc.tabBarItem = tabbarItem
                viewControllers.append(nvc)
            case .messages:
                let vc = MessagesController.instanceFromStoryboard()
                let router = MessagesRouter(dependencies: dependencies, sourceViewController: vc)
                let vm = MessagesViewModel(dependencies: dependencies, router: router)
                vc.viewModel = vm
                let nvc = UINavigationController(rootViewController: vc)
                if #available(iOS 11.0, *) {
                    nvc.navigationBar.prefersLargeTitles = true
                }
                let tabbarItem = UITabBarItem(
                    title: "  ", image: Assets.Images.icTabMessages.image, tag: messagesTabTag)
//                tabbarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 50)
                tabbarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
                vc.tabBarItem = tabbarItem
                viewControllers.append(nvc)
            case .notices:
                let vc = NoticesController.instanceFromStoryboard()
                let router = NoticesRouter(dependencies: dependencies, sourceViewController: vc)
                let vm = NoticesViewModel(dependencies: dependencies, router: router)
                vc.viewModel = vm
                let nvc = UINavigationController(rootViewController: vc)
                if #available(iOS 11.0, *) {
                    nvc.navigationBar.prefersLargeTitles = true
                }
                let tabbarItem = UITabBarItem(
                    title: "  ", image: Assets.Images.icTabAnnouncement.image, tag: announcementsTabTag)
//                tabbarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 50)
                tabbarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
                vc.tabBarItem = tabbarItem
                viewControllers.append(nvc)
            case .diary:
                let vc = DiaryController.instanceFromStoryboard()
                let vm = DiaryViewModel(dependencies: dependencies)
                vc.viewModel = vm
                let nvc = UINavigationController(rootViewController: vc)
                let tabbarItem = UITabBarItem(title: "  ", image: Assets.Images.icTabDairy.image, tag: diarytabTag)
//                tabbarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 50)
                tabbarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
                vc.tabBarItem = tabbarItem
                viewControllers.append(nvc)
            default:
                continue
            }
        }
        tabsController?.viewControllers = viewControllers
        openTab(for: .diary)
        viewModel.rootTabRouterDidLoad()
    }

    func sideMenuItemSelected(_ section: AllowedSection) {
        switch section {
        case .updates, .diary, .messages, .notices:
            openTab(for: section)
        case .finalMarks, .schedule, .marks:
            openSectionInCurrentTab(section)
        case .aboutApp:
            openAboutScreen()
        default:
            return
        }
        sideMenyController?.hideLeftViewAnimated(nil)
    }

    func openAboutScreen() {
        let vc = AboutController.instanceFromStoryboard()
        let nvc = UINavigationController(rootViewController: vc)
        let closeButton = UIBarButtonItem(image: Assets.Images.icClose.image, style: .plain, target: nil, action: nil)
        closeButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.rootViewController?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        vc.navigationItem.leftBarButtonItem = closeButton
        self.rootViewController?.present(nvc, animated: true, completion: nil)
    }

    func openSectionInCurrentTab(_ section: AllowedSection) {
        if case .finalMarks = section {
            let vc = FinalAssesmentsController.instanceFromStoryboard()
            let vm = FinalAssesmentsViewModel(dependencies: dependencies)
            vc.viewModel = vm
            pushControllerOnAvailableNavController(vc)
        }

        if case .schedule = section {
            let vc = ScheduleController.instanceFromStoryboard()
            let vm = ScheduleViewModel(dependencies: dependencies)
            vc.viewModel = vm
            pushControllerOnAvailableNavController(vc)
        }

        if case .marks = section {
            let vc = MarksController.instanceFromStoryboard()
            let vm = MarksViewModel(dependencies: dependencies)
            vc.viewModel = vm
            pushControllerOnAvailableNavController(vc)
        }
    }

    func openTab(for section: AllowedSection) {
        guard let tabVC = tabsController, let viewControllers = tabVC.viewControllers else { return }

        var tagToSelect = updatesTabTag
        switch section {
        case .updates:
            tagToSelect = updatesTabTag
        case .messages:
            tagToSelect = messagesTabTag
        case .diary:
            tagToSelect = diarytabTag
        case .notices:
            tagToSelect = announcementsTabTag
        default:
            return
        }

        TooltipManager.shared().dismiss()

        let selectedIndex = tabVC.selectedIndex
        let indexToSelect = viewControllers.enumerated().filter({ $1.tabBarItem.tag == tagToSelect }).first?.offset
        guard let index = indexToSelect,
            index <= viewControllers.count - 1,
            let currentNVC = viewControllers[index] as? UINavigationController else { return }
        if index == selectedIndex {
            currentNVC.popToRootViewController(animated: false)
        } else {
            tabVC.selectedIndex = index
            currentNVC.popToRootViewController(animated: false)
        }
    }

    func pushControllerOnAvailableNavController(_ controller: UIViewController) {
        guard let tabVC = tabsController, let nvc = tabVC.selectedViewController as? UINavigationController else {
            return
        }
        TooltipManager.shared().dismiss()
        nvc.pushViewController(controller, animated: false)
    }

}
