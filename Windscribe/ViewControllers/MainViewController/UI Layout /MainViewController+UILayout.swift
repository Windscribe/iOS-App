//
//  MainViewController+UILayout.swift
//  Windscribe
//
//  Created by Thomas on 22/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController {
    func addAutoLayoutConstraints() {
        flagBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        serverListTableView.translatesAutoresizingMaskIntoConstraints = false
        favTableView.translatesAutoresizingMaskIntoConstraints = false
        staticIpTableView.translatesAutoresizingMaskIntoConstraints = false
        staticIPTableViewFooterView.translatesAutoresizingMaskIntoConstraints = false
        customConfigTableView.translatesAutoresizingMaskIntoConstraints = false
        customConfigTableViewFooterView.translatesAutoresizingMaskIntoConstraints = false
        listSelectionView.translatesAutoresizingMaskIntoConstraints = false
        preferencesTapAreaButton.translatesAutoresizingMaskIntoConstraints = false
        logoIcon.translatesAutoresizingMaskIntoConstraints = false
        notificationDot.translatesAutoresizingMaskIntoConstraints = false
        connectButtonView.translatesAutoresizingMaskIntoConstraints = false
        locationNameView.translatesAutoresizingMaskIntoConstraints = false
        spacer.translatesAutoresizingMaskIntoConstraints = false
        connectionStateInfoView.translatesAutoresizingMaskIntoConstraints = false
        wifiInfoView.translatesAutoresizingMaskIntoConstraints = false
        ipInfoView.translatesAutoresizingMaskIntoConstraints = false
        freeAccountViewFooterView.translatesAutoresizingMaskIntoConstraints = false
        logoStackView.translatesAutoresizingMaskIntoConstraints = false
        notificationsTapAreaButton.translatesAutoresizingMaskIntoConstraints = false

        let isSmaller = UIDevice.current.isIphone5orLess()

        listSelectionViewTopConstraint = listSelectionView.topAnchor.constraint(equalTo: flagBackgroundView.topAnchor, constant: flagBackgroundView.topSpace + 16)
        listSelectionViewBottomConstraint = listSelectionView.bottomAnchor.constraint(equalTo: flagBackgroundView.bottomAnchor)
        NSLayoutConstraint.activate([
            // flagBackgroundView
            flagBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            flagBackgroundView.rightAnchor.constraint(equalTo: view.rightAnchor),
            flagBackgroundView.leftAnchor.constraint(equalTo: view.leftAnchor),

            // listSelectionView
            listSelectionViewBottomConstraint,
            listSelectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listSelectionView.heightAnchor.constraint(equalToConstant: listSelectionView.viewHeight),

            // connectionStateInfoView
            connectionStateInfoView.topAnchor.constraint(equalTo: view.topAnchor, constant: flagBackgroundView.barHeight + 16),
            connectionStateInfoView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
            connectionStateInfoView.heightAnchor.constraint(equalToConstant: 21),

            // locationNameView
            locationNameView.topAnchor.constraint(equalTo: connectionStateInfoView.bottomAnchor),
            locationNameView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
            locationNameView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),

            // wifiInfoView
            wifiInfoView.topAnchor.constraint(equalTo: locationNameView.bottomAnchor, constant: 8),
            wifiInfoView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 7),
            wifiInfoView.heightAnchor.constraint(equalToConstant: 32),
            wifiInfoView.bottomAnchor.constraint(equalTo: flagBackgroundView.bottomAnchor, constant: -1*(listSelectionView.viewHeight + 14)),

            // ipInfoView
            ipInfoView.centerYAnchor.constraint(equalTo: wifiInfoView.centerYAnchor),
            ipInfoView.leftAnchor.constraint(equalTo: wifiInfoView.rightAnchor, constant: 8),
            ipInfoView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -5),

            // connectButtonView
            connectButtonView.topAnchor.constraint(equalTo: view.topAnchor, constant: flagBackgroundView.barHeight - connectButtonView.topPadding),
            connectButtonView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: connectButtonView.rightPadding),

            // preferencesTapAreaButton
            preferencesTapAreaButton.bottomAnchor.constraint(equalTo: flagBackgroundView.topNavBarHeader.bottomAnchor, constant: -18),
            preferencesTapAreaButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: isSmaller ? 16 : 18),
            preferencesTapAreaButton.heightAnchor.constraint(equalToConstant: isSmaller ? 20 : 24),
            preferencesTapAreaButton.widthAnchor.constraint(equalToConstant: isSmaller ? 20 : 24),

            // logoStackView
            logoStackView.centerYAnchor.constraint(equalTo: preferencesTapAreaButton.centerYAnchor),
            logoStackView.leftAnchor.constraint(equalTo: preferencesTapAreaButton.rightAnchor, constant: 16),
            logoStackView.heightAnchor.constraint(equalToConstant: isSmaller ? 16 : 18),

            // proIcon
            proIcon.widthAnchor.constraint(equalToConstant: isSmaller ? 39 : 44),

            // logoIcon
            logoIcon.widthAnchor.constraint(equalToConstant: isSmaller ? 110 : 124),

            // notificationDot
            notificationDot.topAnchor.constraint(equalTo: logoStackView.topAnchor, constant: -5),
            notificationDot.rightAnchor.constraint(equalTo: logoStackView.rightAnchor, constant: 16),
            notificationDot.heightAnchor.constraint(equalToConstant: 14),
            notificationDot.widthAnchor.constraint(equalToConstant: 14),

            // notificationsTapAreaButton - large tap area covering logo, PRO icon, and notification badge
            notificationsTapAreaButton.topAnchor.constraint(equalTo: logoStackView.topAnchor, constant: -12),
            notificationsTapAreaButton.bottomAnchor.constraint(equalTo: logoStackView.bottomAnchor, constant: 12),
            notificationsTapAreaButton.leftAnchor.constraint(equalTo: logoStackView.leftAnchor, constant: -8),
            notificationsTapAreaButton.rightAnchor.constraint(equalTo: logoStackView.rightAnchor, constant: 24),

            // scrollView
            scrollView.topAnchor.constraint(equalTo: listSelectionView.bottomAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),

            // serverListTableViews
            serverListTableView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            serverListTableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            serverListTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // freeAccountViewFooterView
            freeAccountViewFooterView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            freeAccountViewFooterView.widthAnchor.constraint(equalTo: view.widthAnchor),

            // favTableView
            favTableView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            favTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            favTableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            favTableView.leftAnchor.constraint(equalTo: serverListTableView.rightAnchor),

            // favTableView
            staticIpTableView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            staticIpTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            staticIpTableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            staticIpTableView.leftAnchor.constraint(equalTo: favTableView.rightAnchor),

            // customConfigTableView
            customConfigTableView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            customConfigTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customConfigTableView.widthAnchor.constraint(equalTo: view.widthAnchor),
            customConfigTableView.leftAnchor.constraint(equalTo: staticIpTableView.rightAnchor),

            // staticIPTableViewFooterView
            staticIPTableViewFooterView.centerXAnchor.constraint(equalTo: staticIpTableView.centerXAnchor),
            staticIPTableViewFooterView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            staticIPTableViewFooterView.widthAnchor.constraint(equalTo: view.widthAnchor),
            staticIPTableViewFooterView.heightAnchor.constraint(equalToConstant: UIScreen.hasTopNotch ? 65 : 50),

            // customConfigTableViewFooterView
            customConfigTableViewFooterView.centerXAnchor.constraint(equalTo: customConfigTableView.centerXAnchor),
            customConfigTableViewFooterView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customConfigTableViewFooterView.widthAnchor.constraint(equalTo: view.widthAnchor),
            customConfigTableViewFooterView.heightAnchor.constraint(equalToConstant: UIScreen.hasTopNotch ? 65 : 50)
        ])
    }
}
