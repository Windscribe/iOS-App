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
            scrollView.contentSize = CGSize(width: view.frame.width * 4, height: 0)
            view.setNeedsLayout()
            cardHeaderWasSelected(with: .all)
        }
        flagBackgroundView.redraw()
        listSelectionView.redrawGradientView()
    }

    func addViews() {
        view.backgroundColor = UIColor.nightBlue
        addConnectionViews()

        scrollView = WScrollView()
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(width: view.frame.width * 4, height: 0)
        view.addSubview(scrollView)

        serverListTableView = PlainExpyTableView()
        serverListTableView.tag = 0
        serverListTableView.clipsToBounds = false
        serverListTableView.register(
            NodeTableViewCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.nodeCellReuseIdentifier)
        serverListTableView.register(
            ServerSectionCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.serverSectionCellReuseIdentifier)
        serverListTableView.register(
            BestLocationCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.bestLocationCellReuseIdentifier)
        scrollView.addSubview(serverListTableView)

        // Set table headers
        serverHeaderView = Assembler.container.resolve(ServerInfoView.self)!
        serverListTableView.tableHeaderView = serverHeaderView

        favTableView = PlainTableView()
        favTableView.tag = 1
        favTableView.register(
            FavNodeTableViewCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.favNodeCellReuseIdentifier)
        scrollView.addSubview(favTableView)

        favTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        favTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        favTableViewRefreshControl.backView = RefreshControlViewBack(frame: favTableViewRefreshControl.bounds)
        favTableView.tableHeaderView = ListHeaderView(type: .favNodes, isDarkMode: viewModel.isDarkMode)

        staticIpTableView = PlainTableView()
        staticIpTableView.tag = 3
        staticIPTableViewFooterView = StaticIPListFooterView()
        staticIPTableViewFooterView.viewModel = viewModel
        staticIpTableView.tableFooterView = staticIPTableViewFooterView
        staticIpTableView.register(
            StaticIPTableViewCell.self,
            forCellReuseIdentifier: ReuseIdentifiers.staticIPCellReuseIdentifier)
        scrollView.addSubview(staticIpTableView)

        staticIpTableView.addSubview(staticIPTableViewFooterView)

        staticIpTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        staticIpTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        staticIpTableViewRefreshControl.backView = RefreshControlViewBack(frame: staticIpTableViewRefreshControl.bounds)
        staticIpTableView.tableHeaderView = ListHeaderView(type: .staticIP, isDarkMode: viewModel.isDarkMode)

        customConfigTableView = PlainTableView()
        customConfigTableView.tag = 4
        customConfigTableViewFooterView = CustomConfigListFooterView()
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
        customConfigsTableViewRefreshControl.backView = RefreshControlViewBack(frame: customConfigsTableViewRefreshControl.bounds)
        customConfigTableView.tableHeaderView = ListHeaderView(type: .customConfig, isDarkMode: viewModel.isDarkMode)

        addRefreshControls()

        freeAccountViewFooterView = Assembler.container.resolve(FreeAccountFooterView.self)!
        freeAccountViewFooterView.delegate = self
        scrollView.addSubview(freeAccountViewFooterView)

        view.bringSubviewToFront(scrollView)
    }

    func setTableViewInsets() {
        guard let session = try? viewModel.session.value() else { return }
        if session.isPremium {
            serverListTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            favTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            staticIpTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            customConfigTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            serverListTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            favTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            staticIpTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            customConfigTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        }
    }

    func setHeaderViewSelector() {
        switch scrollView.contentOffset.x {
        case 0:
            selectedHeaderViewTab = .all
            tableViewScrolled(toTop: serverListTableView.contentOffset.y <= 0)
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
            ipInfoView.viewModel.updateCardHeaderType(with: headerType)
        }
    }

    @objc func showCustomConfigTab() {
        cardHeaderWasSelected(with: .config)
    }

    func addConnectionViews() {
        flagBackgroundView = Assembler.resolve(FlagsBackgroundView.self)
        view.addSubview(flagBackgroundView)

        logoIcon = ImageButton()
        logoIcon.imageView?.contentMode = .scaleAspectFit
        logoIcon.addTarget(self, action: #selector(notificationsButtonTapped), for: .touchUpInside)
        logoIcon.setImage(UIImage(named: ImagesAsset.logoText), for: .normal)
        logoIcon.imageView?.setImageColor(color: .white)
        view.addSubview(logoIcon)

        preferencesTapAreaButton = LargeTapAreaImageButton()
        preferencesTapAreaButton.imageView?.contentMode = .scaleAspectFit
        preferencesTapAreaButton.layer.opacity = 0.4
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

        connectButtonView = Assembler.resolve(ConnectButtonView.self)
        view.addSubview(connectButtonView)

        connectionStateInfoView = Assembler.resolve(ConnectionStateInfoView.self)
        connectionStateInfoView.delegate = self
        view.addSubview(connectionStateInfoView)

        ipInfoView = Assembler.resolve(IPInfoView.self)
        view.addSubview(ipInfoView)

        wifiInfoView = Assembler.resolve(WifiInfoView.self)
        view.addSubview(wifiInfoView)

        connectedCityLabel = UILabel()
        connectedCityLabel.adjustsFontSizeToFitWidth = true
        addConnectionLabel(label: connectedCityLabel,
                           font: UIFont.bold(size: 26),
                           color: UIColor.white,
                           text: TextsAsset.bestLocation)

        connectedServerLabel = UILabel()
        connectedServerLabel.adjustsFontSizeToFitWidth = true
        addConnectionLabel(label: connectedServerLabel,
                           font: UIFont.regular(size: 26),
                           color: UIColor.white,
                           text: "")

        spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        view.addSubview(spacer)
    }

    func arrangeListsFooterViews() {
        guard let session = try? viewModel.session.value() else { return }
        let visible = session.isPremium || session.billingPlanId == -9 || !isSpaceAvailableForGetMoreDataView()
        staticIPTableViewFooterView.isHidden = (staticIPListTableViewDataSource?.shouldHideFooter() ?? true) || !visible
        customConfigTableViewFooterView.isHidden = !visible
        if customConfigListTableViewDataSource?.customConfigs?.count == 0 {
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
