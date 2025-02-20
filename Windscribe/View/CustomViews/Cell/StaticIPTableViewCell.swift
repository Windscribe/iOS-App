//
//  StaticIPTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-25.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class StaticIPTableViewCell: BaseNodeTableViewCell {
    var serverIcon = UIImageView()
    var serverNameLabel = UILabel()
    var ipAddressLabel = UILabel()
    var displayingStaticIP: StaticIPModel? {
        didSet {
            updateUI()
        }
    }

    lazy var preferences = Assembler.resolve(Preferences.self)
    private let disposeBag = DisposeBag()
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setPressState(active: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setPressState(active: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setPressState(active: false)
    }

    private func setPressState(active: Bool) {
        if active {
            serverNameLabel.layer.opacity = 1
            ipAddressLabel.layer.opacity = 1
            serverIcon.layer.opacity = 1
            signalBarsIcon.layer.opacity = 1
            latencyLabel.layer.opacity = 1
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.serverNameLabel.layer.opacity = 0.4
                self?.ipAddressLabel.layer.opacity = 0.4
                self?.serverIcon.layer.opacity = 0.4
                self?.signalBarsIcon.layer.opacity = 0.4
                self?.latencyLabel.layer.opacity = 0.4
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.clear

        addSubview(serverIcon)

        serverNameLabel.font = UIFont.bold(size: 14)
        serverNameLabel.textColor = UIColor.midnight
        serverNameLabel.layer.opacity = 0.4
        addSubview(serverNameLabel)

        ipAddressLabel.font = UIFont.text(size: 14)
        ipAddressLabel.layer.opacity = 0.4
        ipAddressLabel.textColor = UIColor.midnight
        addSubview(ipAddressLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        serverIcon.translatesAutoresizingMaskIntoConstraints = false
        serverNameLabel.translatesAutoresizingMaskIntoConstraints = false
        ipAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        latencyBackground.translatesAutoresizingMaskIntoConstraints = false
        latencyLabel.translatesAutoresizingMaskIntoConstraints = false
        signalBarsIcon.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: serverIcon, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 13),
            NSLayoutConstraint(item: serverIcon, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: serverIcon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: serverIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
        ])
        addConstraints([
            NSLayoutConstraint(item: serverNameLabel, attribute: .centerY, relatedBy: .equal, toItem: serverIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverNameLabel, attribute: .left, relatedBy: .equal, toItem: serverIcon, attribute: .right, multiplier: 1.0, constant: 16)
        ])
        addConstraints([
            NSLayoutConstraint(item: ipAddressLabel, attribute: .centerY, relatedBy: .equal, toItem: serverIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: ipAddressLabel, attribute: .right, relatedBy: .equal, toItem: signalBarsIcon, attribute: .left, multiplier: 1.0, constant: -24)
        ])
        addConstraints([
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .centerY, relatedBy: .equal, toItem: ipAddressLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .width, relatedBy: .equal, toItem: latencyLabel, attribute: .width, multiplier: 1.0, constant: 0)
        ])
        addConstraints([
            NSLayoutConstraint(item: latencyLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: latencyBackground, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: latencyLabel as Any, attribute: .centerX, relatedBy: .equal, toItem: latencyBackground, attribute: .centerX, multiplier: 1.0, constant: 0)
        ])
        addConstraints([
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .centerY, relatedBy: .equal, toItem: ipAddressLabel, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
        ])
    }

    func updateUI() {
        latencyLabel.text = ""
        signalBarsIcon.image = cellSignalBarsLow
        serverNameLabel.isEnabled = true
        ipAddressLabel.isEnabled = true
        serverIcon.layer.opacity = 0.5
        if let bestNode = displayingStaticIP?.bestNode, let bestNodeHostname = bestNode.ip1, bestNode.forceDisconnect == false {
            displayLatencyValues(pingIp: bestNodeHostname)
        } else {
            serverNameLabel.isEnabled = false
            ipAddressLabel.isEnabled = false
            signalBarsIcon.image = cellSignalBarsDown
            latencyLabel.text = "  --  "
        }
        serverNameLabel.text = displayingStaticIP?.cityName
        ipAddressLabel.text = displayingStaticIP?.staticIP

        showForLatencySelection()
    }

    func showForLatencySelection() {
        preferences.getLatencyType().subscribe(onNext: { latency in
            if latency == Fields.Values.bars {
                self.signalBarsIcon.isHidden = false
                self.latencyBackground.isHidden = true
                self.latencyLabel.isHidden = true
            } else {
                self.latencyBackground.isHidden = false
                self.latencyLabel.isHidden = false
                self.signalBarsIcon.isHidden = true
            }
        }).disposed(by: disposeBag)
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(onNext: { isDarkMode in
            if !isDarkMode {
                self.cellDivider.backgroundColor = UIColor.midnight
                self.serverNameLabel.textColor = UIColor.midnight
                self.ipAddressLabel.textColor = UIColor.midnight
                self.latencyLabel.textColor = UIColor.midnight
                self.latencyBackground.backgroundColor = UIColor.midnight
                if self.displayingStaticIP?.type == "dc" {
                    self.serverIcon.image = UIImage(named: ImagesAsset.staticIPdc)
                } else {
                    self.serverIcon.image = UIImage(named: ImagesAsset.staticIPres)
                }
            } else {
                self.cellDivider.backgroundColor = UIColor.white
                self.serverNameLabel.textColor = UIColor.white
                self.ipAddressLabel.textColor = UIColor.white
                self.latencyLabel.textColor = UIColor.white
                self.latencyBackground.backgroundColor = UIColor.white
                if self.displayingStaticIP?.type == "dc" {
                    self.serverIcon.image = UIImage(named: ImagesAsset.DarkMode.staticIPdc)
                } else {
                    self.serverIcon.image = UIImage(named: ImagesAsset.DarkMode.staticIPres)
                }
            }
        }).disposed(by: disposeBag)
    }
}
