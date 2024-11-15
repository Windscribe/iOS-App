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

        self.view.addConstraints([
            NSLayoutConstraint(item: backgroundView as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: backgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: 50)
            ])

        if UIScreen.hasTopNotch {
            self.view.addConstraints([
                NSLayoutConstraint(item: flagView as Any, attribute: .height, relatedBy: .equal, toItem: self.backgroundView, attribute: .height, multiplier: 1.0, constant: -140)
            ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: flagView as Any, attribute: .height, relatedBy: .equal, toItem: self.backgroundView, attribute: .height, multiplier: 1.0, constant: -100)
            ])
        }

        flagViewTopConstraint = NSLayoutConstraint(item: flagView as Any, attribute: .top, relatedBy: .equal, toItem: self.protocolLabel, attribute: .bottom, multiplier: 1.0, constant: 0)

        self.view.addConstraints([
            flagViewTopConstraint,
            NSLayoutConstraint(item: flagView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: -30),
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBackgroundView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
            ])
         self.view.addConstraints([
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .top, relatedBy: .equal, toItem: self.connectedServerLabel, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.flagView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: flagBottomGradientView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0)
        ])
        cardViewTopConstraint = NSLayoutConstraint(item: cardView as Any, attribute: .top, relatedBy: .equal, toItem: self.trustedNetworkValueLabel, attribute: .bottom, multiplier: 1.0, constant: 13)
        self.view.addConstraints([
            cardViewTopConstraint,
            NSLayoutConstraint(item: cardView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: cardTopView as Any, attribute: .top, relatedBy: .equal, toItem: self.cardView, attribute: .top, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardTopView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardTopView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cardTopView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .top, relatedBy: .equal, toItem: self.cardTopView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: headerGradientView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 23)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: scrollView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: scrollView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: serverListTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverListTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverListTableView as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: favTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: favTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: favTableView as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: favTableView as Any, attribute: .left, relatedBy: .equal, toItem: serverListTableView, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: streamingTableView as Any, attribute: .left, relatedBy: .equal, toItem: favTableView, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIpTableView as Any, attribute: .left, relatedBy: .equal, toItem: streamingTableView, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        if UIScreen.hasTopNotch {
            self.view.addConstraints([
                NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 65)
                ])
            self.view.addConstraints([
                NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 65)
                ])

        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
                ])
            self.view.addConstraints([
                NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 50)
                ])
        }
        self.view.addConstraints([
            NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .centerX, relatedBy: .equal, toItem: customConfigTableView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableViewFooterView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .centerX, relatedBy: .equal, toItem: staticIpTableView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: staticIPTableViewFooterView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0)
            ])
        view.addConstraints([
            NSLayoutConstraint(item: customConfigTableView as Any, attribute: .top, relatedBy: .equal, toItem: serverHeaderView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableView as Any, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: customConfigTableView as Any, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1.0, constant: 0),
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
            self.view.addConstraints([
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 100)
                ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: 0),
                NSLayoutConstraint(item: topNavBarImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 70)
                ])
        }

        self.view.addConstraints([
            NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .centerY, relatedBy: .equal, toItem: self.logoIcon, attribute: .centerY, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 18)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: logoIcon as Any, attribute: .bottom, relatedBy: .equal, toItem: self.topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -18)
        ])
        if UIDevice.current.isIphone5orLess() {
            self.view.addConstraints([
                NSLayoutConstraint(item: logoIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 17),
                NSLayoutConstraint(item: logoIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 110),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 15),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 17)
                ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: logoIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 21),
                NSLayoutConstraint(item: logoIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 126),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 17),
                NSLayoutConstraint(item: preferencesTapAreaButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 19)
                ])
        }
        self.view.addConstraints([
            NSLayoutConstraint(item: logoIcon as Any, attribute: .left, relatedBy: .equal, toItem: self.preferencesTapAreaButton, attribute: .right, multiplier: 1.0, constant: 18)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: notificationDot as Any, attribute: .top, relatedBy: .equal, toItem: self.logoIcon, attribute: .top, multiplier: 1.0, constant: -5),
            NSLayoutConstraint(item: notificationDot as Any, attribute: .right, relatedBy: .equal, toItem: self.logoIcon, attribute: .right, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: notificationDot as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: notificationDot as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 14)
            ])
        if UIDevice.current.isIphone6() {
            self.view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -8),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 84),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 84)
                ])
            self.view.addConstraints([
                NSLayoutConstraint(item: connectButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -14),
                NSLayoutConstraint(item: connectButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 72),
                NSLayoutConstraint(item: connectButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 72)
                ])
        } else if UIDevice.current.isIphone5orLess() {
            self.view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -8),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 74),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 74)
                ])
            self.view.addConstraints([
                NSLayoutConstraint(item: connectButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -14),
                NSLayoutConstraint(item: connectButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 62),
                NSLayoutConstraint(item: connectButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 62)
                ])
        } else {
            self.view.addConstraints([
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -16),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 96),
                NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 96)
                ])
            self.view.addConstraints([
                NSLayoutConstraint(item: connectButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -24),
                NSLayoutConstraint(item: connectButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 80),
                NSLayoutConstraint(item: connectButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 80)
                ])
        }
        if UIScreen.hasTopNotch {
            self.view.addConstraints([
                  NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .top, relatedBy: .equal, toItem: self.topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -50)
            ])
        } else if UIDevice.current.isIpad {
            self.view.addConstraints([
                  NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .top, relatedBy: .equal, toItem: self.topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -25)
            ])
        } else {
            self.view.addConstraints([
                  NSLayoutConstraint(item: connectButtonRingView as Any, attribute: .top, relatedBy: .equal, toItem: self.topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: -35)
            ])
        }
         self.view.addConstraints([
               NSLayoutConstraint(item: connectButton as Any, attribute: .centerY, relatedBy: .equal, toItem: self.connectButtonRingView, attribute: .centerY, multiplier: 1.0, constant: 0)
         ])
        self.view.addConstraints([
            NSLayoutConstraint(item: statusView as Any, attribute: .top, relatedBy: .equal, toItem: self.topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusView as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusView as Any, attribute: .right, relatedBy: .lessThanOrEqual, toItem: self.connectButtonRingView, attribute: .left, multiplier: 1.0, constant: -10),
            NSLayoutConstraint(item: statusView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: statusView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 36)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: statusImageView as Any, attribute: .centerY, relatedBy: .equal, toItem: self.statusView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusImageView as Any, attribute: .centerX, relatedBy: .equal, toItem: self.statusView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 12),
            NSLayoutConstraint(item: statusImageView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 12)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .centerY, relatedBy: .equal, toItem: self.statusView, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .centerX, relatedBy: .equal, toItem: self.statusView, attribute: .centerX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: connectivityTestImageView as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 22)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: statusLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.topNavBarImageView, attribute: .bottom, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .right, relatedBy: .lessThanOrEqual, toItem: self.connectButtonRingView, attribute: .left, multiplier: 1.0, constant: -10),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 20),
            NSLayoutConstraint(item: statusLabel as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 36)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: protocolLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.statusLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: protocolLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.statusLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: protocolLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 15)
        ])
        self.view.addConstraints([
            NSLayoutConstraint(item: statusDivider as Any, attribute: .centerY, relatedBy: .equal, toItem: self.statusLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: statusDivider as Any, attribute: .left, relatedBy: .equal, toItem: self.protocolLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: statusDivider as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 10),
            NSLayoutConstraint(item: statusDivider as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 1)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: portLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.statusLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: portLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.statusDivider, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: portLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 15)
        ])
        preferredBadgeConstraints = [
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .centerY, relatedBy: .equal, toItem: self.portLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .left, relatedBy: .equal, toItem: self.portLabel, attribute: .right, multiplier: 1.0, constant: 8),
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 10),
            NSLayoutConstraint(item: preferredProtocolBadge as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 0)
        ]
        self.view.addConstraints(preferredBadgeConstraints)
         circumventCensorshipBadgeConstraints = [
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .centerY, relatedBy: .equal, toItem: self.preferredProtocolBadge, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .left, relatedBy: .equal, toItem: self.preferredProtocolBadge, attribute: .right, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 14),
            NSLayoutConstraint(item: circumventCensorshipBadge as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 0)
        ]
        self.view.addConstraints(circumventCensorshipBadgeConstraints)
        changeProtocolArrowConstraints = [
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .centerY, relatedBy: .equal, toItem: self.portLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .left, relatedBy: .equal, toItem: self.circumventCensorshipBadge, attribute: .right, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40),
            NSLayoutConstraint(item: changeProtocolArrow as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 40)
        ]
        self.view.addConstraints(changeProtocolArrowConstraints)
        self.view.addConstraints([
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.statusLabel, attribute: .bottom, multiplier: 1.0, constant: 12),
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.connectButton, attribute: .left, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: connectedCityLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 40)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .top, relatedBy: .equal, toItem: self.connectedCityLabel, attribute: .bottom, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -6),
            NSLayoutConstraint(item: connectedServerLabel as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 30)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: trustedNetworkIcon as Any, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: trustedNetworkIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 23),
            NSLayoutConstraint(item: trustedNetworkIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 23)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: trustedNetworkValueLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.trustedNetworkIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: trustedNetworkValueLabel as Any, attribute: .left, relatedBy: .equal, toItem: trustedNetworkIcon, attribute: .right, multiplier: 1.0, constant: 6),
            NSLayoutConstraint(item: trustedNetworkValueLabel as Any, attribute: .right, relatedBy: .equal, toItem: spacer, attribute: .left, multiplier: 1.0, constant: -8)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .centerY, relatedBy: .equal, toItem: self.yourIPValueLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .right, relatedBy: .equal, toItem: self.yourIPValueLabel, attribute: .left, multiplier: 1.0, constant: -6),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .left, relatedBy: .equal, toItem: self.spacer, attribute: .right, multiplier: 1.0, constant: -6),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: yourIPIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
            ])
        self.view.addConstraints([
            NSLayoutConstraint(item: yourIPValueLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: self.trustedNetworkIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: yourIPValueLabel as Any, attribute: .right, relatedBy: .equal, toItem: self.expandButton, attribute: .left, multiplier: 1.0, constant: -16)
            ])

        self.view.addConstraints([
            NSLayoutConstraint(item: expandButton as Any, attribute: .centerY, relatedBy: .equal, toItem: self.trustedNetworkIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: expandButton as Any, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: expandButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: expandButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 24)
        ])
    }
}
