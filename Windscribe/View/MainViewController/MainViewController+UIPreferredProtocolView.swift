//
//  MainViewController+UIPreferredProtocolView.swift
//  Windscribe
//
//  Created by Thomas on 22/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension MainViewController {
    func hidePreferredProtocolView() {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
                guard let self = self else { return }
                self.preferredProtocolLabel.isHidden = true
                self.preferredProtocolInfoButton.isHidden = true
                self.preferredProtocolSwitch.isHidden = true
                self.cellDivider1.isHidden = true
                self.view.removeConstraint(self.cardViewTopConstraint)
                self.cardViewTopConstraint = NSLayoutConstraint(item: self.cardView as Any, attribute: .top, relatedBy: .equal, toItem: self.autoSecureLabel, attribute: .bottom, multiplier: 1.0, constant: 13)
                self.view.addConstraint(self.cardViewTopConstraint)
                self.view.layoutIfNeeded()
            })
        }
    }

    func showPreferredProtocolView() {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
                guard let self = self else { return }
                self.view.removeConstraint(self.cardViewTopConstraint)
                self.cardViewTopConstraint = NSLayoutConstraint(item: self.cardView as Any, attribute: .top, relatedBy: .equal, toItem: self.preferredProtocolLabel, attribute: .bottom, multiplier: 1.0, constant: 13)
                self.view.addConstraint(self.cardViewTopConstraint)
                self.view.layoutIfNeeded()
                self.preferredProtocolLabel.isHidden = false
                self.preferredProtocolInfoButton.isHidden = false
                self.preferredProtocolSwitch.isHidden = false
                self.cellDivider1.isHidden = false
            })
        }
    }

    func hideProtocolSelectionView() {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
                guard let self = self else { return }
                self.protocolSelectionLabel.isHidden = true
                self.protocolDropdownButton.isHidden = true
                self.portSelectionLabel.isHidden = true
                self.portDropdownButton.isHidden = true
                self.manualViewDivider1.isHidden = true
                self.view.removeConstraint(self.cardViewTopConstraint)
                self.cardViewTopConstraint = NSLayoutConstraint(item: self.cardView as Any, attribute: .top, relatedBy: .equal, toItem: self.preferredProtocolLabel, attribute: .bottom, multiplier: 1.0, constant: 13)
                self.view.addConstraint(self.cardViewTopConstraint)
                self.view.layoutIfNeeded()
            })
        }
    }

    func showProtocolSelectionView() {
        DispatchQueue.main.async { [weak self] in
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
                guard let self = self else { return }
                self.view.removeConstraint(self.cardViewTopConstraint)
                self.cardViewTopConstraint = NSLayoutConstraint(item: self.cardView as Any, attribute: .top, relatedBy: .equal, toItem: self.portSelectionLabel, attribute: .bottom, multiplier: 1.0, constant: 13)
                self.view.addConstraint(self.cardViewTopConstraint)
                self.view.layoutIfNeeded()
                self.protocolSelectionLabel.isHidden = false
                self.protocolDropdownButton.isHidden = false
                self.portSelectionLabel.isHidden = false
                self.portDropdownButton.isHidden = false
                self.manualViewDivider1.isHidden = false
            })
        }
    }
}
