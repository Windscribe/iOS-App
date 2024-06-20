//
//  BestLocationHeaderView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class BestLocationCell: UITableViewCell {
    var flagIcon = UIImageView()
    var serverNameLabel =  UILabel()
    var cellDivider = UIView()
    var serverHealthView = ServerHealthView()
    var displayingBestLocation: BestLocationModel? {
        didSet {
            updateUI()
        }
    }
    lazy var preferences = Assembler.resolve(Preferences.self)
    var disposeBag = DisposeBag()
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
        addSubview(flagIcon)

        serverNameLabel.font = UIFont.bold(size: 14)
        serverNameLabel.textColor = UIColor.midnight
        serverNameLabel.layer.opacity = 0.4
        addSubview(serverNameLabel)
        cellDivider.backgroundColor = UIColor.black
        cellDivider.layer.opacity = 0.05
        addSubview(cellDivider)

        addSubview(serverHealthView)

        flagIcon.translatesAutoresizingMaskIntoConstraints = false
        serverNameLabel.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false
        serverHealthView.translatesAutoresizingMaskIntoConstraints = false

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
            NSLayoutConstraint(item: serverNameLabel,
                               attribute: .centerY,
                               relatedBy: .equal,
                               toItem: flagIcon,
                               attribute: .centerY,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: serverNameLabel,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: flagIcon,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: 16)
            ])
        addConstraints([
            NSLayoutConstraint(item: cellDivider,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 2),
            NSLayoutConstraint(item: cellDivider,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: -2),
            NSLayoutConstraint(item: cellDivider,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: 24),
            NSLayoutConstraint(item: cellDivider,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: 0)
            ])

        addConstraints([
            NSLayoutConstraint(item: serverHealthView,
                               attribute: .height,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: .height,
                               multiplier: 1.0,
                               constant: 2),
            NSLayoutConstraint(item: serverHealthView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: -2),
            NSLayoutConstraint(item: serverHealthView,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: 24),
            NSLayoutConstraint(item: serverHealthView,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: -32)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag() // Force rx disposal on reuse
    }

    func updateUI() {
        if let countryCode = displayingBestLocation?.countryCode {
            serverNameLabel.text = TextsAsset.bestLocation
            flagIcon.image = UIImage(named: "\(countryCode)-s.png")
        }
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        preferences.getShowServerHealth().subscribe(onNext: { serverHealth in
            if let serverHealth = serverHealth {
                if serverHealth {
                    self.serverHealthView.health = self.displayingBestLocation?.health
                } else {
                    self.serverHealthView.health = 0
                }

            }
        }).disposed(by: disposeBag)
        isDarkMode.subscribe( onNext: { isDark in
            self.backgroundColor = ThemeUtils.backgroundColor(isDarkMode: isDark)
            self.cellDivider.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            self.serverNameLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            self.flagIcon.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            self.flagIcon.layer.shadowColor = ThemeUtils.primaryTextColor(isDarkMode: isDark).cgColor
        }).disposed(by: disposeBag)
    }
}
