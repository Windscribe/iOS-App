//
//  MainViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import UIKit
import Swinject

extension MainViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if scrollView != nil {
            scrollView.contentSize = CGSize(width: size.width * 4, height: 0)
            view.setNeedsLayout()
            cardHeaderWasSelected(with: .all)
        }
        flagBackgroundView.redraw()
        listSelectionView.redrawGradientView()

        // After the transition completes, force a full layout pass so all
        // subviews (header, gradient, flags) pick up the new window bounds.
        // This fixes stale layouts when switching between floating and
        // full-screen window modes on iPadOS.
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.view.layoutIfNeeded()
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            // Re-assert dark mode on the window to prevent mixed style after
            // iPad floating ↔ full-screen transitions.
            self.overrideUserInterfaceStyle = .dark
            self.navigationController?.overrideUserInterfaceStyle = .dark
            self.view.window?.overrideUserInterfaceStyle = .dark
            self.flagBackgroundView.redraw()
            self.listSelectionView.redrawGradientView()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        })
    }

    func addDataSources() {
        locationsListTableViewDataSource = Assembler.resolve(LocationsListTableViewDataSource.self)
        favoriteListTableViewDataSource = Assembler.resolve(FavouriteListTableViewDataSource.self)
        staticIPListTableViewDataSource = Assembler.resolve(StaticIPListTableViewDataSource.self)

        customConfigListTableViewDataSource = Assembler.resolve(CustomConfigListTableViewDataSource.self)

        locationsListTableView.dataSource = locationsListTableViewDataSource
        locationsListTableView.delegate = locationsListTableViewDataSource
        locationsListTableViewDataSource.delegate = self

        favTableView.dataSource = favoriteListTableViewDataSource
        favTableView.delegate = favoriteListTableViewDataSource
        favoriteListTableViewDataSource.delegate = self

        staticIpTableView.dataSource = staticIPListTableViewDataSource
        staticIpTableView.delegate = staticIPListTableViewDataSource
        staticIPListTableViewDataSource.delegate = self
        staticIPListTableViewDataSource.makeEmptyView(tableView: staticIpTableView)
        staticIPTableViewFooterView.delegate = staticIPListViewModel
        staticIPTableViewFooterView.updateDeviceName()

        customConfigTableView.dataSource = customConfigListTableViewDataSource
        customConfigTableView.delegate = customConfigListTableViewDataSource
        customConfigListTableViewDataSource.uiDelegate = self
        customConfigListTableViewDataSource.logicDelegate = customConfigPickerViewModel

        reloadFavouriteOrder()
    }

    func addViews() {
        view.backgroundColor = UIColor.nightBlue
        addConnectionViews()

        scrollView = WSScrollView()
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(width: view.frame.width * 4, height: 0)
        view.addSubview(scrollView)

        locationsListTableView = PlainExpyTableView()
        locationsListTableView.tag = 0
        locationsListTableView.clipsToBounds = false
        locationsListTableView.register(
            DatacenterTableViewCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.datacenterCellReuseIdentifier)
        locationsListTableView.register(
            LocationSectionCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.locationSectionCellReuseIdentifier)
        locationsListTableView.register(
            BestLocationCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)
        scrollView.addSubview(locationsListTableView)

        // Set table headers
        serverHeaderView = Assembler.resolve(ServerInfoView.self)
        locationsListTableView.tableHeaderView = serverHeaderView

        favTableView = PlainTableView()
        favTableView.tag = 1
        favTableView.register(
            FavNodeTableViewCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier)
        scrollView.addSubview(favTableView)

        favTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        favTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        favTableViewRefreshControl.backView = RefreshControlBackView(frame: favTableViewRefreshControl.bounds)
        let favHeaderView = Assembler.resolve(ListHeaderView.self)
        favHeaderView.viewModel.updateType(with: .favorites)
        favTableView.tableHeaderView = favHeaderView

        staticIpTableView = PlainTableView()
        staticIpTableView.tag = 3
        let languageManager = Assembler.resolve(LanguageManager.self)
        staticIPTableViewFooterView = StaticIPListFooterView(activeLanguage: languageManager.activelanguage)
        staticIPTableViewFooterView.viewModel = viewModel
        staticIpTableView.tableFooterView = staticIPTableViewFooterView
        staticIpTableView.register(
            StaticIPTableViewCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.staticIPCellReuseIdentifier)
        scrollView.addSubview(staticIpTableView)

        staticIpTableView.addSubview(staticIPTableViewFooterView)

        staticIpTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        staticIpTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        staticIpTableViewRefreshControl.backView = RefreshControlBackView(frame: staticIpTableViewRefreshControl.bounds)
        let staticHeaderView = Assembler.resolve(ListHeaderView.self)
        staticHeaderView.viewModel.updateType(with: .staticIP)
        staticIpTableView.tableHeaderView = staticHeaderView

        customConfigTableView = PlainTableView()
        customConfigTableView.tag = 4
        let lookAndFeelRepository = Assembler.resolve(LookAndFeelRepositoryType.self)
        customConfigTableViewFooterView = CustomConfigListFooterView(activeLanguage: languageManager.activelanguage, isDarkMode: lookAndFeelRepository.isDarkModeSubject)
        customConfigTableViewFooterView.delegate = customConfigPickerViewModel
        customConfigTableView.tableFooterView = customConfigTableViewFooterView
        customConfigTableView.register(
            CustomConfigCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.customConfigCellReuseIdentifier)
        customConfigTableView.allowsMultipleSelectionDuringEditing = false
        scrollView.addSubview(customConfigTableView)
        customConfigTableView.addSubview(customConfigTableViewFooterView)

        customConfigsTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        customConfigsTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        customConfigsTableViewRefreshControl.backView = RefreshControlBackView(frame: customConfigsTableViewRefreshControl.bounds)
        let customHeaderView = Assembler.resolve(ListHeaderView.self)
        customHeaderView.viewModel.updateType(with: .customConfig)
        customConfigTableView.tableHeaderView = customHeaderView

        addDataSources()
        addRefreshControls()

        freeAccountViewFooterView = Assembler.resolve(FreeAccountFooterView.self)
        freeAccountViewFooterView.delegate = self
        scrollView.addSubview(freeAccountViewFooterView)

        view.bringSubviewToFront(scrollView)
    }

    func setTableViewInsets(for session: SessionModel?) {
        logger.logI("MainViewController", "setTableViewInsets")
        guard let session = session else { return }
        if session.isPremium {
            locationsListTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            favTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            staticIpTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            customConfigTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            locationsListTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            favTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            staticIpTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            customConfigTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        }
    }

    func setHeaderViewSelector() {
        switch scrollView.contentOffset.x {
        case 0:
            selectedHeaderViewTab = .all
            tableViewScrolled(toTop: locationsListTableView.contentOffset.y <= 0)
        case view.frame.width:
            selectedHeaderViewTab = .fav
            tableViewScrolled(toTop: favTableView.contentOffset.y <= 0)
        case view.frame.width * 2:
            selectedHeaderViewTab = .staticIP
            tableViewScrolled(toTop: staticIpTableView.contentOffset.y <= 0)
        case view.frame.width * 3:
            selectedHeaderViewTab = .config
            tableViewScrolled(toTop: customConfigTableView.contentOffset.y <= 0)
        default:
            return
        }
        if let headerType = selectedHeaderViewTab {
            listSelectionView.viewModel
                .setSelectedAction(selectedAction: headerType)
        }
    }

    @objc func showCustomConfigTab() {
        cardHeaderWasSelected(with: .config)
    }

    func addConnectionViews() {
        flagBackgroundView = Assembler.resolve(FlagsBackgroundView.self)
        view.addSubview(flagBackgroundView)

        logoStackView = UIStackView()
        logoStackView.axis = .horizontal
        logoStackView.spacing = 0
        view.addSubview(logoStackView)

        logoIcon = ImageButton()
        logoIcon.imageView?.contentMode = .scaleAspectFit
        logoIcon.addTarget(self, action: #selector(notificationsButtonTapped), for: .touchUpInside)

        proIcon = ImageButton()
        proIcon.imageView?.contentMode = .scaleAspectFit
        proIcon.addTarget(self, action: #selector(notificationsButtonTapped), for: .touchUpInside)

        logoIcon.setImage(UIImage(named: ImagesAsset.logoText), for: .normal)
        logoIcon.imageView?.setImageColor(color: .white)
        logoStackView.addArrangedSubview(logoIcon)

        proIcon.setImage(UIImage(named: ImagesAsset.proUserIcon), for: .normal)
        proIcon.imageView?.setImageColor(color: .white)
        logoStackView.addArrangedSubview(proIcon)

        preferencesTapAreaButton = LargeTapAreaImageButton()
        preferencesTapAreaButton.imageView?.contentMode = .scaleAspectFit
        preferencesTapAreaButton.layer.opacity = 0.7
        preferencesTapAreaButton.setImage(UIImage(named: ImagesAsset.topNavBarMenu), for: .normal)
        preferencesTapAreaButton.imageView?.setImageColor(color: .white)
        view.addSubview(preferencesTapAreaButton)

        notificationDot = ImageButton()
        notificationDot.backgroundColor = UIColor.seaGreen
        notificationDot.layer.cornerRadius = 7.0
        notificationDot.clipsToBounds = true
        notificationDot.isHidden = true
        notificationDot.setTitleColor(UIColor.midnight, for: .normal)
        notificationDot.titleLabel?.font = UIFont.bold(size: 10)
        notificationDot.addTarget(self, action: #selector(notificationsButtonTapped), for: .touchUpInside)
        view.addSubview(notificationDot)

        // Large transparent tap area covering logo, PRO icon, and notification badge
        notificationsTapAreaButton = UIButton()
        notificationsTapAreaButton.backgroundColor = .clear
        notificationsTapAreaButton.addTarget(self, action: #selector(notificationsButtonTapped), for: .touchUpInside)
        view.addSubview(notificationsTapAreaButton)

        connectButtonView = Assembler.resolve(ConnectButtonView.self)
        view.addSubview(connectButtonView)

        connectionStateInfoView = Assembler.resolve(ConnectionStateInfoView.self)
        connectionStateInfoView.delegate = self
        view.addSubview(connectionStateInfoView)

        locationNameView = Assembler.resolve(LocationNameView.self)
        view.addSubview(locationNameView)

        ipInfoView = Assembler.resolve(IPInfoView.self)
        view.addSubview(ipInfoView)

        wifiInfoView = Assembler.resolve(WifiInfoView.self)
        view.addSubview(wifiInfoView)

        spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        view.addSubview(spacer)
    }

    func arrangeListsFooterViews(for sessionModel: SessionModel) {
        let visible = sessionModel.isUserPro || !isSpaceAvailableForGetMoreDataView()
        staticIPTableViewFooterView.isHidden = staticIPListTableViewDataSource.shouldHideFooter() || !visible
        customConfigTableViewFooterView.isHidden = !visible
        if customConfigListTableViewDataSource.customConfigs.count == 0 {
            customConfigTableViewFooterView.isHidden = true
        }
    }

    private func isSpaceAvailableForGetMoreDataView() -> Bool {
        switch scrollView.contentOffset.x {
        case 0, view.frame.width, view.frame.width * 2:
            return true
        default:
            return false
        }
    }

    func addConnectionLabel(label: UILabel, font: UIFont, color: UIColor, text: String) {
        label.font = font
        label.text = text
        label.textColor = color
        view.addSubview(label)
    }
}
