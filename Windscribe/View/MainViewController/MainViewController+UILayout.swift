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
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        flagBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        flagView.translatesAutoresizingMaskIntoConstraints = false
        flagBottomGradientView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        serverListTableView.translatesAutoresizingMaskIntoConstraints = false
        favTableView.translatesAutoresizingMaskIntoConstraints = false
        streamingTableView.translatesAutoresizingMaskIntoConstraints = false
        staticIpTableView.translatesAutoresizingMaskIntoConstraints = false
        staticIPTableViewFooterView.translatesAutoresizingMaskIntoConstraints = false
        customConfigTableView.translatesAutoresizingMaskIntoConstraints = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardTopView.translatesAutoresizingMaskIntoConstraints = false
        serverHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headerGradientView.translatesAutoresizingMaskIntoConstraints = false
        headerBottomBorderView.translatesAutoresizingMaskIntoConstraints = false
        customConfigTableViewFooterView.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: backgroundView as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: 50)
        ])

        if UIScreen.hasTopNotch {
            view.addConstraints([
                NSLayoutConstraint(item: flagView as Any, attribute: .height, relatedBy: .equal, toItem: backgroundView, attribute: .height, multiplier: 1.0, constant: -140)
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: flagView as Any, attribute: .height, relatedBy: .equal, toItem: backgroundView, attribute: .height, multiplier: 1.0, constant: -100)
            ])
        }

        flagViewTopConstraint = NSLayoutConstraint(item: flagView as Any, attribute: .top, relatedBy: .equal, toItem: protocolLabel, attribute: .bottom, multiplier: 1.0, constant: 0)

        view.addConstraints([
            flagViewTopConstraint,
            NSLayoutConstraint(item: flagView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: -30),
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .top, relatedBy: .equal, toItem: connectedServerLabel, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .bottom, relatedBy: .equal, toItem: flagView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0)
        ])
        cardViewTopConstraint = NSLayoutConstraint(item: cardView as Any, attribute: .top, relatedBy: .equal, toItem: trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: 13)
        view.addConstraints([
            cardViewTopConstraint,
            NSLayoutConstraint(item: cardView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: cardTopView as Any, attribute: .top, relatedBy: .equal, toItem: cardView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardTopView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardTopView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardTopView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .top, relatedBy: .equal, toItem: cardTopView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 23)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: scrollView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: serverListTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverListTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverListTableView as Any, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: favTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: favTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: favTableView as Any, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: favTableView as Any, attribute: .left, relatedBy: .equal, toItem: serverListTableView, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .left, relatedBy: .equal, toItem: favTableView, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .left, relatedBy: .equal, toItem: streamingTableView, attribute: .right, multiplier: 1.0, constant: 0)
        ])
        if UIScreen.hasTopNotch {
            view.addConstraints([
                NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 65)
            ])
            view.addConstraints([
                NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 65)
            ])

        } else {
            view.addConstraints([
                NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
            ])
            view.addConstraints([
                NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
            ])
        }
        view.addConstraints([
            NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .centerX, relatedBy: .equal, toItem: customConfigTableView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .centerX, relatedBy: .equal, toItem: staticIpTableView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: customConfigTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableView as Any, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableView as Any, attribute: .left, relatedBy: .equal, toItem: staticIpTableView, attribute: .right, multiplier: 1.0, constant: 0)
        ])

        view.addConstraints([
            NSLayoutConstraint(item: serverHeaderView as Any, attribute: .top, relatedBy: .equal, toItem: cardView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverHeaderView as Any, attribute: .left, relatedBy: .equal, toItem: cardView, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverHeaderView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: headerBottomBorderView as Any, attribute: .bottom, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerBottomBorderView as Any, attribute: .left, relatedBy: .equal, toItem: cardView, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerBottomBorderView as Any, attribute: .right, relatedBy: .equal, toItem: cardView, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerBottomBorderView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2)
        ])
    }

    func addAutoLayoutConstraintsForConnectionViews() {
        topNavBarImageView.translatesAutoresizingMaskIntoConstraints = false
        preferencesTapAreaButton.translatesAutoresizingMaskIntoConstraints = false
        logoIcon.translatesAutoresizingMaskIntoConstraints = false
        notificationDot.translatesAutoresizingMaskIntoConstraints = false
        connectButtonRingView.translatesAutoresizingMaskIntoConstraints = false
        connectButton.translatesAutoresizingMaskIntoConstraints = false
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusImageView.translatesAutoresizingMaskIntoConstraints = false
        connectivityTestImageView.translatesAutoresizingMaskIntoConstraints = false
        statusDivider.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        protocolLabel.translatesAutoresizingMaskIntoConstraints = false
        portLabel.translatesAutoresizingMaskIntoConstraints = false
        preferredProtocolBadge.translatesAutoresizingMaskIntoConstraints = false
        changeProtocolArrow.translatesAutoresizingMaskIntoConstraints = false
        connectedCityLabel.translatesAutoresizingMaskIntoConstraints = false
        connectedServerLabel.translatesAutoresizingMaskIntoConstraints = false
        yourIPValueLabel.translatesAutoresizingMaskIntoConstraints = false
        trustedNetworkValueLabel.translatesAutoresizingMaskIntoConstraints = false
        yourIPIcon.translatesAutoresizingMaskIntoConstraints = false
        spacer.translatesAutoresizingMaskIntoConstraints = false
        trustedNetworkIcon.translatesAutoresizingMaskIntoConstraints = false
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        circumventCensorshipBadge.translatesAutoresizingMaskIntoConstraints = false

        if UIScreen.hasTopNotch {
            view.addConstraints([
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 100)
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 70)
            ])
        }

        view.addConstraints([
            NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .centerY, relatedBy: .equal, toItem: logoIcon, attribute: .centerY, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 18)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: logoIcon as Any, attribute: .bottom, relatedBy: .equal, toItem: topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -18)
        ])
        if UIDevice.current.isIphone5orLess() {
            view.addConstraints([
                NSLayoutConstraint(item: logoIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 17),
                NSLayoutConstraint(item: logoIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 110),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 15),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 17)
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: logoIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 21),
                NSLayoutConstraint(item: logoIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 126),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 17),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 19)
            ])
        }
        view.addConstraints([
            NSLayoutConstraint(item: logoIcon as Any, attribute: .left, relatedBy: .equal, toItem: preferencesTapAreaButton, attribute: .right, multiplier: 1.0, constant: 18)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: notificationDot as Any, attribute: .top, relatedBy: .equal, toItem: logoIcon, attribute: .top, multiplier: 1.0, constant: -5),
            NSLayoutConstraint(item: notificationDot as Any, attribute: .right, relatedBy: .equal, toItem: logoIcon, attribute: .right, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: notificationDot as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: notificationDot as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 14)
        ])
        if UIDevice.current.isIphone6() {
            view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -8),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 84),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 84)
            ])
            view.addConstraints([
                NSLayoutConstraint(item: connectButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -14),
                NSLayoutConstraint(item: connectButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 72),
                NSLayoutConstraint(item: connectButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 72)
            ])
        } else if UIDevice.current.isIphone5orLess() {
            view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -8),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 74),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 74)
            ])
            view.addConstraints([
                NSLayoutConstraint(item: connectButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -14),
                NSLayoutConstraint(item: connectButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 62),
                NSLayoutConstraint(item: connectButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 62)
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 96),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 96)
            ])
            view.addConstraints([
                NSLayoutConstraint(item: connectButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -24),
                NSLayoutConstraint(item: connectButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 80),
                NSLayoutConstraint(item: connectButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 80)
            ])
        }
        if UIScreen.hasTopNotch {
            view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .top, relatedBy: .equal, toItem: topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -50)
            ])
        } else if UIDevice.current.isIpad {
            view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .top, relatedBy: .equal, toItem: topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -25)
            ])
        } else {
            view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .top, relatedBy: .equal, toItem: topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -35)
            ])
        }
        view.addConstraints([
            NSLayoutConstraint(item: connectButton as Any, attribute: .centerY, relatedBy: .equal, toItem: connectButtonRingView, attribute: .centerY, multiplier: 1.0, constant: 0)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: statusView as Any, attribute: .top, relatedBy: .equal, toItem: topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusView as Any, attribute: .right, relatedBy: .lessThanOrEqual, toItem: connectButtonRingView, attribute: .left, multiplier: 1.0, constant: -10),
            NSLayoutConstraint(item: statusView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: statusView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 36)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: statusImageView as Any, attribute: .centerY, relatedBy: .equal, toItem: statusView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusImageView as Any, attribute: .centerX, relatedBy: .equal, toItem: statusView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 12),
            NSLayoutConstraint(item: statusImageView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 12)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .centerY, relatedBy: .equal, toItem: statusView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .centerX, relatedBy: .equal, toItem: statusView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 22)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: statusLabel as Any, attribute: .top, relatedBy: .equal, toItem: topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .right, relatedBy: .lessThanOrEqual, toItem: connectButtonRingView, attribute: .left, multiplier: 1.0, constant: -10),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 36)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: protocolLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: statusLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: protocolLabel as Any, attribute: .left, relatedBy: .equal, toItem: statusLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: protocolLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 15)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: statusDivider as Any, attribute: .centerY, relatedBy: .equal, toItem: statusLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusDivider as Any, attribute: .left, relatedBy: .equal, toItem: protocolLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: statusDivider as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 10),
            NSLayoutConstraint(item: statusDivider as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 1)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: portLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: statusLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: portLabel as Any, attribute: .left, relatedBy: .equal, toItem: statusDivider, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: portLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 15)
        ])
        preferredBadgeConstraints = [
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .centerY, relatedBy: .equal, toItem: portLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .left, relatedBy: .equal, toItem: portLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 10),
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 0)
        ]
        view.addConstraints(preferredBadgeConstraints)
        circumventCensorshipBadgeConstraints = [
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .centerY, relatedBy: .equal, toItem: preferredProtocolBadge, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .left, relatedBy: .equal, toItem: preferredProtocolBadge, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 0)
        ]
        view.addConstraints(circumventCensorshipBadgeConstraints)
        changeProtocolArrowConstraints = [
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .centerY, relatedBy: .equal, toItem: portLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .left, relatedBy: .equal, toItem: circumventCensorshipBadge, attribute: .right, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40),
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 40)
        ]
        view.addConstraints(changeProtocolArrowConstraints)
        view.addConstraints([
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .top, relatedBy: .equal, toItem: statusLabel, attribute: .bottom, multiplier: 1.0, constant: 12),
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .right, relatedBy: .equal, toItem: connectButton, attribute: .left, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .top, relatedBy: .equal, toItem: connectedCityLabel, attribute: .bottom, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -6),
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 30)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: trustedNetworkIcon as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: trustedNetworkIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 23),
            NSLayoutConstraint(item: trustedNetworkIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 23)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: trustedNetworkValueLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: trustedNetworkIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: trustedNetworkValueLabel as Any, attribute: .left, relatedBy: .equal, toItem: trustedNetworkIcon, attribute: .right, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: trustedNetworkValueLabel as Any, attribute: .right, relatedBy: .equal, toItem: spacer, attribute: .left, multiplier: 1.0, constant: -8)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .centerY, relatedBy: .equal, toItem: yourIPValueLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .right, relatedBy: .equal, toItem: yourIPValueLabel, attribute: .left, multiplier: 1.0, constant: -6),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .left, relatedBy: .equal, toItem: spacer, attribute: .right, multiplier: 1.0, constant: -6),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
        ])
        view.addConstraints([
            NSLayoutConstraint(item: yourIPValueLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: trustedNetworkIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: yourIPValueLabel as Any, attribute: .right, relatedBy: .equal, toItem: expandButton, attribute: .left, multiplier: 1.0, constant: -16)
        ])

        view.addConstraints([
            NSLayoutConstraint(item: expandButton as Any, attribute: .centerY, relatedBy: .equal, toItem: trustedNetworkIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: expandButton as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: expandButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: expandButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 24)
        ])
    }
}
