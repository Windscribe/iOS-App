//
//  ServerTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class ServerSectionCell: UITableViewCell {
    var proIcon = UIImageView()
    var flagIcon = UIImageView()
    var serverNameLabel =  UILabel()
    var iconView = UIImageView()
    var p2pImage = UIImageView()
    var cellDivider = UIView()
    var cellDividerFull = UIView()
    var serverHealthView = ServerHealthView()
    var section: Int = 0
    var tableViewTag: Int = 0
    var displayingServer: ServerModel? {
        didSet {
            updateUI()
        }
    }
    var preferences: Preferences {
       return Assembler.resolve(Preferences.self)
    }
    var sessionManager: SessionManagerV2 {
        return Assembler.resolve(SessionManagerV2.self)
    }
    let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.white

        flagIcon.layer.masksToBounds = false
        flagIcon.backgroundColor = UIColor.midnight
        flagIcon.layer.shadowColor = UIColor.midnight.cgColor
        flagIcon.layer.shadowOpacity = 0.1
        flagIcon.layer.shadowOffset = CGSize(width: 2, height: 2)
        flagIcon.layer.shadowRadius = 0.0
        contentView.addSubview(flagIcon)

        contentView.addSubview(proIcon)
        serverNameLabel.font = UIFont.bold(size: 14)
        serverNameLabel.textColor = UIColor.midnight
        contentView.addSubview(serverNameLabel)
        iconView.image = UIImage(named: ImagesAsset.cellExpand)
        contentView.addSubview(iconView)
        contentView.addSubview(p2pImage)

        cellDivider.backgroundColor = UIColor.black
        cellDivider.layer.opacity = 0.05
        contentView.addSubview(cellDivider)
        cellDividerFull.backgroundColor = UIColor.black
        contentView.addSubview(cellDividerFull)

        contentView.addSubview(serverHealthView)

        showForCollapse()

        flagIcon.translatesAutoresizingMaskIntoConstraints = false
        proIcon.translatesAutoresizingMaskIntoConstraints = false
        serverNameLabel.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false
        cellDividerFull.translatesAutoresizingMaskIntoConstraints = false
        serverHealthView.translatesAutoresizingMaskIntoConstraints = false
        p2pImage.translatesAutoresizingMaskIntoConstraints = false
        addConstraints([
            NSLayoutConstraint(item: flagIcon,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 13),
            NSLayoutConstraint(item: flagIcon,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: 16),
            NSLayoutConstraint(item: flagIcon,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 16),
            NSLayoutConstraint(item: flagIcon,
                               attribute: .width,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .width,
                               multiplier: 1.0,
                               constant: 32)
            ])
        addConstraints([
            NSLayoutConstraint(item: proIcon, attribute: .top, relatedBy: .equal, toItem: flagIcon, attribute: .top, multiplier: 1.0, constant: -8),
            NSLayoutConstraint(item: proIcon, attribute: .left, relatedBy: .equal, toItem: flagIcon, attribute: .left, multiplier: 1.0, constant: -8),
            NSLayoutConstraint(item: proIcon, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: proIcon, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 18)
            ])
        addConstraints([
            NSLayoutConstraint(item: serverNameLabel, attribute: .centerY, relatedBy: .equal, toItem: flagIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: serverNameLabel, attribute: .left, relatedBy: .equal, toItem: flagIcon, attribute: .right, multiplier: 1.0, constant: 16)
            ])
        addConstraints([
            NSLayoutConstraint(item: iconView, attribute: .centerY, relatedBy: .equal, toItem: flagIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: iconView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: iconView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: iconView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
            ])
        addConstraints([
            NSLayoutConstraint(item: p2pImage, attribute: .centerY, relatedBy: .equal, toItem: flagIcon, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: p2pImage, attribute: .right, relatedBy: .equal, toItem: iconView, attribute: .left, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: p2pImage, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: p2pImage, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16)
            ])
        addConstraints([
            NSLayoutConstraint(item: serverHealthView, attribute: .height, relatedBy: .equal, toItem: cellDivider, attribute: .height, multiplier: 1.0, constant: 1),
            NSLayoutConstraint(item: serverHealthView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: serverHealthView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: serverHealthView, attribute: .right, relatedBy: .equal, toItem: iconView, attribute: .left, multiplier: 1.0, constant: 0)
            ])

        addConstraints([
            NSLayoutConstraint(item: cellDivider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: cellDivider, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: cellDivider, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: cellDivider, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0)
            ])
        addConstraints([
            NSLayoutConstraint(item: cellDividerFull, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: cellDividerFull, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: cellDividerFull, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateUI() {
        proIcon.image = nil
        if let serverName = displayingServer?.name, let countryCode = displayingServer?.countryCode, let premiumOnly = displayingServer?.premiumOnly, let isUserPro = sessionManager.session?.isPremium, let isP2p = displayingServer?.p2p {
            serverNameLabel.text = serverName
            flagIcon.image = UIImage(named: "\(countryCode)-s")
            if premiumOnly && !isUserPro {
                self.proIcon.image = UIImage(named: ImagesAsset.proServerIcon)
            }
            if isP2p == true {
                self.p2pImage.isHidden = true
            } else {
                self.p2pImage.isHidden = false
            }
        }
    }

    func setCollapsed(collapsed: Bool, completion: @escaping () -> Void = {}) {
        if collapsed { showForCollapse() } else { showForExpand() }
    }

    func expand(completion: @escaping () -> Void = {}) {
        if self.cellDivider.layer.opacity != 1.0 {
            UIView.animate(withDuration: 0.35, animations: {
               self.showForExpand()
            }, completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }

    func showForExpand() {
        self.cellDividerFull.frame.size.width = self.frame.width
        self.cellDivider.layer.opacity = 1.0
        self.serverNameLabel.layer.opacity = 1.0
        self.iconView.layer.opacity = 1.0
        self.flagIcon.layer.shadowOpacity = 1.0
        self.iconView.transform = CGAffineTransform(rotationAngle: .pi/4)
        self.serverHealthView.isHidden = true
    }

    func collapse(completion: @escaping () -> Void = {}) {
        if self.cellDivider.layer.opacity != 0.05 {
            UIView.animate(withDuration: 0.35, animations: {
               self.showForCollapse()
            }, completion: { _ in
                completion()
            })
        } else {
            completion()
        }
    }

    func showForCollapse() {
        self.cellDividerFull.frame.size.width = 0
        self.cellDivider.layer.opacity = 0.05
        self.serverNameLabel.layer.opacity = 0.4
        self.iconView.layer.opacity = 1
        self.flagIcon.layer.shadowOpacity = 0.1
        self.iconView.transform = CGAffineTransform(rotationAngle: .pi*4)
        self.serverHealthView.isHidden = false
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        preferences.getShowServerHealth().subscribe(on: MainScheduler.asyncInstance).observe(on: MainScheduler.asyncInstance).subscribe(onNext: { serverHealth in
            if let serverHealth = serverHealth {
                if serverHealth {
                    self.serverHealthView.health = self.displayingServer?.getServerHealth()
                } else {
                    self.serverHealthView.health = 0
                }
            }
        }).disposed(by: disposeBag)
        isDarkMode.subscribe( onNext: { isDark in
            if !isDark {
                self.backgroundColor = UIColor.white
                self.cellDivider.backgroundColor = UIColor.midnight
                self.cellDividerFull.backgroundColor = UIColor.midnight
                self.serverNameLabel.textColor = UIColor.midnight
                self.iconView.image = UIImage(named: ImagesAsset.cellExpand)
                self.flagIcon.backgroundColor = UIColor.midnight
                self.flagIcon.layer.shadowColor = UIColor.midnight.cgColor
                if self.proIcon.image != nil {
                    self.proIcon.image = UIImage(named: ImagesAsset.proServerIcon)
                }
                self.p2pImage.image = UIImage(named: ImagesAsset.p2p)
            } else {
                self.backgroundColor = UIColor.lightMidnight
                self.cellDivider.backgroundColor = UIColor.white
                self.cellDividerFull.backgroundColor = UIColor.white
                self.serverNameLabel.textColor = UIColor.white
                self.iconView.image = UIImage(named: ImagesAsset.whiteExpand)
                self.flagIcon.backgroundColor = UIColor.white
                self.flagIcon.layer.shadowColor = UIColor.white.cgColor
                if self.proIcon.image != nil {
                    self.proIcon.image = UIImage(named: ImagesAsset.DarkMode.proServerIcon)
                }
                self.p2pImage.image = UIImage(named: ImagesAsset.p2pWhite)
            }
        }).disposed(by: disposeBag)
    }
}
