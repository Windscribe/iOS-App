//
//  MainViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import UIKit

extension MainViewController {
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradient.frame = flagView.bounds
        backgroundGradient.frame = flagBackgroundView.bounds
        cardTopView.roundCorners(corners: [.topLeft, .topRight], radius: 24)
        cardView.roundCorners(corners: [.topLeft, .topRight], radius: 24)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if scrollView != nil {
            scrollView.contentSize = CGSize(width: view.frame.height * 5, height: 0)
            view.setNeedsLayout()
            cardHeaderWasSelected(with: .all)
        }
    }

    func addViews() {
        view.backgroundColor = UIColor.midnight

        backgroundView = UIView()
        backgroundView.isUserInteractionEnabled = false
        backgroundView.backgroundColor = UIColor.midnight
        view.addSubview(backgroundView)

        flagView = UIImageView()
        flagView.isUserInteractionEnabled = false
        flagView.contentMode = .scaleAspectFill
        flagView.image = UIImage(named: vpnConnectionViewModel.getSelectedCountryCode())
        flagView.layer.opacity = 0.25
        gradient = CAGradientLayer()
        gradient.frame = flagView.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.lightMidnight.cgColor]
        gradient.locations = [0, 0.65]
        flagView.layer.mask = gradient
        view.addSubview(flagView)

        flagBackgroundView = UIView()
        flagBackgroundView.isUserInteractionEnabled = false
        flagBackgroundView.backgroundColor = UIColor.lightMidnight
        backgroundGradient = CAGradientLayer()
        backgroundGradient.frame = flagBackgroundView.bounds
        backgroundGradient.colors = [UIColor.lightMidnight.cgColor, UIColor.clear.cgColor]
        backgroundGradient.locations = [0.0, 1.0]
        flagBackgroundView.layer.mask = backgroundGradient
        view.addSubview(flagBackgroundView)

        flagBottomGradientView = UIImageView()
        flagBottomGradientView.isUserInteractionEnabled = true
        flagBottomGradientView.contentMode = .scaleAspectFill
        flagBottomGradientView.image = UIImage(named: "flag-bottom-gradient")
        view.addSubview(flagBottomGradientView)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedOnScreen))
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        flagBottomGradientView.addGestureRecognizer(tapRecognizer)

        addConnectionViews()
        addAutoSecureViews()

        cardView = UIView()
        cardView.isUserInteractionEnabled = false
        cardView.backgroundColor = UIColor.white
        view.addSubview(cardView)

        cardTopView = UIView()
        cardTopView.isUserInteractionEnabled = true
        cardTopView.backgroundColor = UIColor.white
        cardTopView.layer.opacity = 0.05
        view.addSubview(cardTopView)

        scrollView = WScrollView()
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(width: view.frame.width * 5, height: 0)
        view.addSubview(scrollView)

        serverListTableView = PlainExpyTableView()
        serverListTableView.tag = 0
        serverListTableView.register(NodeTableViewCell.self, forCellReuseIdentifier: nodeCellReuseIdentifier)
        serverListTableView.register(ServerSectionCell.self, forCellReuseIdentifier: serverSectionCellReuseIdentifier)
        serverListTableView.register(BestLocationCell.self, forCellReuseIdentifier: bestLocationCellReuseIdentifier)
        scrollView.addSubview(serverListTableView)

        favTableView = PlainTableView()
        favTableView.tag = 1
        favTableView.register(FavNodeTableViewCell.self, forCellReuseIdentifier: favNodeCellReuseIdentifier)
        scrollView.addSubview(favTableView)

        favTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        favTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        favTableViewRefreshControl.backView = RefreshControlViewBack(frame: favTableViewRefreshControl.bounds)

        streamingTableView = PlainExpyTableView()
        streamingTableView.tag = 2
        streamingTableView.register(NodeTableViewCell.self, forCellReuseIdentifier: nodeCellReuseIdentifier)
        streamingTableView.register(ServerSectionCell.self, forCellReuseIdentifier: serverSectionCellReuseIdentifier)
        scrollView.addSubview(streamingTableView)

        streamingTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        streamingTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        streamingTableViewRefreshControl.backView = RefreshControlViewBack(frame: streamingTableViewRefreshControl.bounds)

        staticIpTableView = PlainTableView()
        staticIpTableView.tag = 3
        staticIPTableViewFooterView = StaticIPListFooterView()
        staticIPTableViewFooterView.viewModel = viewModel
        staticIpTableView.tableFooterView = staticIPTableViewFooterView
        staticIpTableView.register(StaticIPTableViewCell.self, forCellReuseIdentifier: staticIPCellReuseIdentifier)
        scrollView.addSubview(staticIpTableView)

        staticIpTableView.addSubview(staticIPTableViewFooterView)

        staticIpTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        staticIpTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        staticIpTableViewRefreshControl.backView = RefreshControlViewBack(frame: staticIpTableViewRefreshControl.bounds)

        customConfigTableView = PlainTableView()
        customConfigTableView.tag = 4
        customConfigTableViewFooterView = CustomConfigListFooterView()
        customConfigTableViewFooterView.delegate = customConfigPickerViewModel
        customConfigTableView.tableFooterView = customConfigTableViewFooterView
        customConfigTableView.register(CustomConfigTableViewCell.self, forCellReuseIdentifier: customConfigCellReuseIdentifier)
        customConfigTableView.allowsMultipleSelectionDuringEditing = false
        scrollView.addSubview(customConfigTableView)
        customConfigTableView.addSubview(customConfigTableViewFooterView)

        customConfigsTableViewRefreshControl = WSRefreshControl(isDarkMode: viewModel.isDarkMode)
        customConfigsTableViewRefreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        customConfigsTableViewRefreshControl.backView = RefreshControlViewBack(frame: customConfigsTableViewRefreshControl.bounds)

        addRefreshControls()

        view.bringSubviewToFront(cardView)
        view.bringSubviewToFront(cardTopView)
        view.bringSubviewToFront(scrollView)

        serverHeaderView = UIView()
        serverHeaderView.isUserInteractionEnabled = false
        serverHeaderView.backgroundColor = UIColor.clear
        cardView.addSubview(serverHeaderView)

        headerBottomBorderView = UIView()
        headerBottomBorderView.backgroundColor = UIColor.clear
        serverHeaderView.addSubview(headerBottomBorderView)

        headerGradientView = UIView()
        headerGradientView.isUserInteractionEnabled = false
        headerGradientView.isHidden = true
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 10)
        gradient.colors = [UIColor.midnightWithOpacity(opacity: 0.2).cgColor, UIColor.midnightWithOpacity(opacity: 0).cgColor]
        headerGradientView.layer.insertSublayer(gradient, at: 0)
        view.addSubview(headerGradientView)

        view.bringSubviewToFront(headerGradientView)
    }

    func setTableViewInsets() {
        guard let session = try? viewModel.session.value() else { return }
        if session.isPremium {
            serverListTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            favTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            streamingTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            staticIpTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            customConfigTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            serverListTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            favTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            streamingTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            staticIpTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
            customConfigTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        }
    }

    func hideHeaderGradient(hide: Bool) {
        headerGradientView.isHidden = hide
    }

    func setHeaderViewSelector() {
        switch scrollView.contentOffset.x {
        case 0:
            selectedHeaderViewTab = .all
            tableViewScrolled(toTop: serverListTableView.contentOffset.y <= 0)
            cardHeaderContainerView.viewModel.setSelectedAction(selectedAction: .all)
            arrangeDataLeftViews()
        case view.frame.width:
            selectedHeaderViewTab = .fav
            tableViewScrolled(toTop: favTableView.contentOffset.y <= 0)
            cardHeaderContainerView.viewModel.setSelectedAction(selectedAction: .fav)
            arrangeDataLeftViews()
        case view.frame.width * 2:
            selectedHeaderViewTab = .flix
            tableViewScrolled(toTop: streamingTableView.contentOffset.y <= 0)
            cardHeaderContainerView.viewModel.setSelectedAction(selectedAction: .flix)
            arrangeDataLeftViews()
        case view.frame.width * 3:
            selectedHeaderViewTab = .staticIP
            tableViewScrolled(toTop: staticIpTableView.contentOffset.y <= 0)
            cardHeaderContainerView.viewModel.setSelectedAction(selectedAction: .staticIP)
            arrangeDataLeftViews()
        case view.frame.width * 4:
            selectedHeaderViewTab = .config
            tableViewScrolled(toTop: customConfigTableView.contentOffset.y <= 0)
            cardHeaderContainerView.viewModel.setSelectedAction(selectedAction: .config)
        default:
            return
        }
    }

    @objc func showCustomConfigTab() {
        cardHeaderWasSelected(with: .config)
    }

    func setTopNavImage(white: Bool) {
        if UIScreen.hasTopNotch {
            if white {
                topNavBarImageView.image = UIImage(named: ImagesAsset.topNavWhiteForNotch)
            } else {
                topNavBarImageView.image = UIImage(named: ImagesAsset.topNavBlackForNotch)
            }
        } else if UIDevice.current.isIpad {
            if white {
                topNavBarImageView.image = UIImage(named: ImagesAsset.topNavWhiteSliced)
            } else {
                topNavBarImageView.image = UIImage(named: ImagesAsset.topNavBlackSliced)
            }
        } else {
            if white {
                topNavBarImageView.image = UIImage(named: ImagesAsset.topNavWhite)
            } else {
                topNavBarImageView.image = UIImage(named: ImagesAsset.topNavBlack)
            }
        }
    }

    func addConnectionViews() {
        topNavBarImageView = UIImageView()
        topNavBarImageView.layer.opacity = 0.10
        topNavBarImageView.isUserInteractionEnabled = false
        setTopNavImage(white: false)

        view.addSubview(topNavBarImageView)

        logoIcon = ImageButton()
        logoIcon.imageView?.contentMode = .scaleAspectFit
        logoIcon.addTarget(self, action: #selector(notificationsButtonTapped), for: .touchUpInside)
        logoIcon.setImage(UIImage(named: ImagesAsset.logoText), for: .normal)
        view.addSubview(logoIcon)
        view.bringSubviewToFront(logoIcon)

        preferencesTapAreaButton = LargeTapAreaImageButton()
        preferencesTapAreaButton.imageView?.contentMode = .scaleAspectFit
        preferencesTapAreaButton.layer.opacity = 0.4
        preferencesTapAreaButton.addTarget(self, action: #selector(logoButtonTapped), for: .touchUpInside)
        preferencesTapAreaButton.setImage(UIImage(named: ImagesAsset.topNavBarMenu), for: .normal)
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

        connectButtonRingView = UIImageView()
        connectButtonRingView.image = UIImage(named: ImagesAsset.connectButtonRing)
        connectButtonRingView.isHidden = true
        view.addSubview(connectButtonRingView)

        connectButton = UIButton()
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        connectButton.setImage(UIImage(named: ImagesAsset.disconnectedButton), for: .normal)
        view.addSubview(connectButton)

        statusView = UIView()
        statusView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        statusView.layer.cornerRadius = 10
        statusView.clipsToBounds = true
        view.addSubview(statusView)

        statusImageView = UIImageView()
        statusImageView.contentMode = .scaleAspectFit
        statusImageView.isHidden = true
        view.addSubview(statusImageView)

        connectivityTestImageView = UIImageView()
        connectivityTestImageView.contentMode = .scaleAspectFit
        connectivityTestImageView.isHidden = true
        view.addSubview(connectivityTestImageView)

        statusLabel = UILabel()
        statusLabel.textAlignment = .center
        statusLabel.adjustsFontSizeToFitWidth = true
        addConnectionLabel(label: statusLabel, font: UIFont.bold(size: 12), color: UIColor.white, text: "")

        protocolLabel = UILabel()
        addConnectionLabel(label: protocolLabel,
                           font: UIFont.bold(size: 12),
                           color: UIColor.white.withAlphaComponent(0.5),
                           text: WifiManager.shared.getConnectedNetwork()?.protocolType ?? TextsAsset.wireGuard)

        statusDivider = UIView()
        statusDivider.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        view.addSubview(statusDivider)

        portLabel = UILabel()
        addConnectionLabel(label: portLabel,
                           font: UIFont.bold(size: 12),
                           color: UIColor.white.withAlphaComponent(0.5),
                           text: WifiManager.shared.getConnectedNetwork()?.port ?? "443")

        preferredProtocolBadge = UIImageView()
        preferredProtocolBadge.isHidden = false
        preferredProtocolBadge.contentMode = .scaleAspectFit
        view.addSubview(preferredProtocolBadge)

        circumventCensorshipBadge = UIImageView()
        circumventCensorshipBadge.isHidden = false
        circumventCensorshipBadge.image = UIImage(named: ImagesAsset.circumventCensorship)?.withRenderingMode(.alwaysTemplate)
        circumventCensorshipBadge.contentMode = .scaleAspectFit
        view.addSubview(circumventCensorshipBadge)

        changeProtocolArrow = UIImageView()
        changeProtocolArrow.isHidden = true
        changeProtocolArrow.contentMode = .scaleAspectFit
        self.changeProtocolArrow.image = UIImage(named: ImagesAsset.connectedArrow)?.withAlignmentRectInsets(UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
        self.view.addSubview(changeProtocolArrow)
        let protocolTapGesture = UITapGestureRecognizer(target: self, action: #selector(protocolPortLableTapped))
        let protocolLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(protocolPortLableTapped))
        let portTapGesture = UITapGestureRecognizer(target: self, action: #selector(protocolPortLableTapped))

        changeProtocolArrow.addGestureRecognizer(protocolTapGesture)
        changeProtocolArrow.isUserInteractionEnabled = true
        protocolLabel.addGestureRecognizer(protocolLabelTapGesture)
        protocolLabel.isUserInteractionEnabled = false
        portLabel.addGestureRecognizer(portTapGesture)
        portLabel.isUserInteractionEnabled = false

        connectedCityLabel = UILabel()
        connectedCityLabel.adjustsFontSizeToFitWidth = true
        addConnectionLabel(label: connectedCityLabel,
                           font: UIFont.bold(size: 32),
                           color: UIColor.white,
                           text: TextsAsset.bestLocation)

        connectedServerLabel = UILabel()
        addConnectionLabel(label: connectedServerLabel, font: UIFont.text(size: 24), color: UIColor.white, text: "")

        yourIPValueLabel = BlurredLabel()
        yourIPValueLabel.isUserInteractionEnabled = true
        let yourIPValueLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(yourIPValueLabelTapped))
        yourIPValueLabelTapGesture.numberOfTapsRequired = 1
        yourIPValueLabel.addGestureRecognizer(yourIPValueLabelTapGesture)
        yourIPValueLabel.tag = 0
        yourIPValueLabel.font = UIFont.text(size: 14)
        yourIPValueLabel.textColor = UIColor.white
        yourIPValueLabel.textAlignment = .left
        yourIPValueLabel.layer.opacity = 0.5
        yourIPValueLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)
        view.addSubview(yourIPValueLabel)

        spacer = UIView()
        spacer.setContentHuggingPriority(UILayoutPriority.defaultLow, for: NSLayoutConstraint.Axis.horizontal)
        view.addSubview(spacer)

        yourIPIcon = UIImageView()
        yourIPIcon.contentMode = .scaleAspectFit
        yourIPIcon.layer.opacity = 0.5
        yourIPIcon.image = UIImage(named: ImagesAsset.unsecure)
        view.addSubview(yourIPIcon)

        trustedNetworkValueLabel = BlurredLabel()
        trustedNetworkValueLabel.textAlignment = .left
        trustedNetworkValueLabel.font = UIFont.bold(size: 14)
        trustedNetworkValueLabel.textColor = UIColor.white
        trustedNetworkValueLabel.layer.opacity = 0.5
        trustedNetworkValueLabel.setContentHuggingPriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)
        trustedNetworkValueLabel.isUserInteractionEnabled = true
        let trustedNetworkValueLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(trustedNetworkValueLabelTapped))
        trustedNetworkValueLabelTapGesture.numberOfTapsRequired = 1
        trustedNetworkValueLabel.addGestureRecognizer(trustedNetworkValueLabelTapGesture)
        view.addSubview(trustedNetworkValueLabel)

        trustedNetworkIcon = UIImageView()
        trustedNetworkIcon.layer.opacity = 0.5
        trustedNetworkIcon.contentMode = .scaleAspectFit
        trustedNetworkIcon.image = UIImage(named: ImagesAsset.wifi)
        view.addSubview(trustedNetworkIcon)

        expandButton = ImageButton()
        expandButton.tag = 0
        expandButton.layer.opacity = 0.5
        expandButton.setImage(UIImage(named: ImagesAsset.expandHome), for: .normal)
        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
        view.addSubview(expandButton)

        addAutoLayoutConstraintsForConnectionViews()
    }

    func arrangeDataLeftViews() {
        guard let session = try? viewModel.session.value() else { return }
        let hide = session.isPremium || session.billingPlanId == -9 || !isSpaceAvailableForGetMoreDataView()
        getMoreDataView.isHidden = hide
        getMoreDataLabel.isHidden = hide
        getMoreDataButton.isHidden = hide
        staticIPTableViewFooterView.isHidden = !hide
        customConfigTableViewFooterView.isHidden = !hide
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
