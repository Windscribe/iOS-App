//
//  AccountTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

protocol AccountTableViewCellDelegate: AnyObject {
    func upgradeButtonTapped(indexPath: IndexPath)
}

class AccountTableViewCell: UITableViewCell {
    lazy var leftLabel = UILabel()
    lazy var rightButton = UIButton()
    lazy var cellDivider = UIView()

    var indexPath: IndexPath = .init()
    weak var delegate: AccountTableViewCellDelegate?
    let configDataTrigger = PublishSubject<Void>()
    private let disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        leftLabel.textColor = UIColor.white
        leftLabel.font = UIFont.bold(size: 16)
        leftLabel.textAlignment = .left
        addSubview(leftLabel)

        rightButton.titleLabel?.textColor = UIColor.white
        rightButton.titleLabel?.font = UIFont.text(size: 16)
        rightButton.titleLabel?.textAlignment = .left
        rightButton.isUserInteractionEnabled = false
        addSubview(rightButton)

        cellDivider.backgroundColor = UIColor.white
        cellDivider.layer.opacity = 0.05
        addSubview(cellDivider)

        setupViews()
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        Observable.combineLatest(configDataTrigger.asObservable(), isDarkMode.asObservable()).bind { [weak self] (_, isDarkMode) in
            self?.cellDivider.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            self?.leftLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            if self?.item == .planType {
                if self?.item.isProUser ?? false {
                    if self?.item.billingPlanId == -9 {
                        self?.rightButton.titleLabel?.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
                    } else {
                        self?.rightButton.titleLabel?.textColor =  isDarkMode ? UIColor.seaGreen : UIColor.connectingStartBlue
                    }
                } else {
                    self?.rightButton.titleLabel?.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
                }
            } else {
                self?.rightButton.titleLabel?.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
            }

            self?.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setupViews() {
        leftLabel.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false

        leftLabel.makeTopAnchor(constant: 16)
        leftLabel.makeLeadingAnchor(constant: 16)
        leftLabel.makeHeightAnchor(equalTo: 20)

        rightButton.centerYAnchor.constraint(equalTo: leftLabel.centerYAnchor).isActive = true
        rightButton.makeTrailingAnchor(constant: 16)

        cellDivider.makeHeightAnchor(equalTo: 2)
        cellDivider.topAnchor.constraint(equalTo: leftLabel.bottomAnchor, constant: 16).isActive = true
        cellDivider.makeLeadingAnchor(constant: 16)
        cellDivider.makeTrailingAnchor()
        cellDivider.makeBottomAnchor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupViews()
    }

    var item: AccountItemCell!

    func configData(item: AccountItemCell) {
        self.item = item
        didSetData()
        configDataTrigger.onNext(())
    }

    private func didSetData() {
        DispatchQueue.main.async {
            self.leftLabel.text = self.item.title
            self.addSubview(self.rightButton)
            self.rightButton.setAttributedTitle(self.item.value, for: .normal)
            self.rightButton.isUserInteractionEnabled = false
            self.rightButton.titleLabel?.font = UIFont.text(size: 16)
            if self.item == .planType {
                if !self.item.isProUser {
                    self.rightButton.addTarget(self, action: #selector(self.upgradeTap), for: .touchUpInside)
                    self.rightButton.isUserInteractionEnabled = true
                }
            }
            self.showHideCellDividerView()
            self.makeRoundCorners()
        }
    }

    @objc func upgradeTap() {
        print("Tapped")
        delegate?.upgradeButtonTapped(indexPath: indexPath)
    }

    private func makeRoundCorners() {
        switch item {
        case .email, .dateLeft:
            makeRoundCorners(corners: [.bottomLeft, .bottomRight], radius: 8)
        case .username, .planType:
            makeRoundCorners(corners: [.topLeft, .topRight], radius: 8)
        case .expiredDate:
            if item.isProUser {
                makeRoundCorners(corners: [.bottomLeft, .bottomRight], radius: 8)
            } else {
                fallthrough
            }
        default:
            makeRoundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 0)
        }
    }

    private func showHideCellDividerView() {
        if item == .email || item == .dateLeft {
            cellDivider.isHidden = true
        } else if item == .expiredDate && item.isProUser {
            cellDivider.isHidden = true
        } else {
            cellDivider.isHidden = false
        }
    }
}
