//
//  AccountTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

protocol AccountTableViewCellDelegate: AnyObject {
    func upgradeButtonTapped(indexPath: IndexPath)
}

class AccountTableViewCell: UITableViewCell {
    lazy var leftLabel = UILabel()
    lazy var rightButton = UIButton()
    lazy var cellDivider = UIView()

    var indexPath: IndexPath = IndexPath()
    weak var delegate: AccountTableViewCellDelegate?
    let configDataTrigger = PublishSubject<()>()
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
        Observable.combineLatest(configDataTrigger.asObservable(), isDarkMode.asObservable()).bind { (_, isDarkMode) in
            self.cellDivider.backgroundColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            self.leftLabel.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            if !self.item.isProUser {
                if self.item.billingPlanId != -9 {
                    self.rightButton.titleLabel?.textColor = ThemeUtils.primaryTextColor50(isDarkMode: isDarkMode)
                } else {
                    self.rightButton.titleLabel?.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
                }
            }
            self.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDarkMode)
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

    private func updateRightButtonPro(_ isPro: Bool) {
        if isPro {
            rightButton.setTitleColor(UIColor.seaGreen, for: .normal)
            rightButton.titleLabel?.font = UIFont.text(size: 16)
            rightButton.titleLabel?.layer.opacity = 1
        } else {
            rightButton.setTitleColor(UIColor.white, for: .normal)
            rightButton.titleLabel?.font = UIFont.text(size: 16)
            rightButton.titleLabel?.layer.opacity = 0.5
        }
    }

    private func didSetData() {
        leftLabel.text = item.title
        if item == .planType {
            if item.isProUser {
                if item.billingPlanId == -9 {
                    rightButton.setTitle(TextsAsset.unlimited, for: .normal)
                } else {
                    rightButton.setTitle(TextsAsset.pro, for: .normal)
                }
                rightButton.titleLabel?.text = TextsAsset.pro
                rightButton.isUserInteractionEnabled = false
                updateRightButtonPro(true)
            } else {
                rightButton.addTarget(self, action: #selector(upgradeTap), for: .touchUpInside)
                addSubview(rightButton)
                rightButton.setTitle(TextsAsset.Account.upgrade, for: .normal)
                rightButton.setTitleColor(.red, for: .normal)
                rightButton.titleLabel?.font =  UIFont.text(size: 16)
                rightButton.isUserInteractionEnabled = true
                updateRightButtonPro(false)
            }
        } else {
            rightButton.addTarget(self, action: #selector(upgradeTap), for: .touchUpInside)
            addSubview(rightButton)
            rightButton.setAttributedTitle(item.value, for: .normal)
            rightButton.isUserInteractionEnabled = true
            updateRightButtonPro(false)
        }

        showHideCellDividerView()
        makeRoundCorners()
    }

    @objc func upgradeTap() {
        print("Tapped")
        delegate?.upgradeButtonTapped(indexPath: self.indexPath)
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
