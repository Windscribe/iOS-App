//
//  AccountEmailCell.swift
//  Windscribe
//
//  Created by Thomas on 09/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import UIKit

enum EmailCellType {
    case confirmEmail
    case email
    case emptyEmail
    case emailPro

    func color(isDarkMode: Bool) -> UIColor {
        switch self {
        case .confirmEmail:
            ThemeUtils.getConfirmLabelColor(isDarkMode: isDarkMode)
        default:
            ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        }
    }
}

protocol AccountEmailCellDelegate: AnyObject {
    func addEmailButtonTapped(indexPath: IndexPath)
}

class AccountEmailCell: UITableViewCell {
    var indexPath: IndexPath = .init()
    weak var delegate: AccountEmailCellDelegate?
    let typeSubject = BehaviorSubject<EmailCellType>(value: .confirmEmail)
    private var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(wrapperView)
        wrapperView.fillSuperview()

        wrapperView.addSubview(mainStack)
        mainStack.fillSuperview()
        mainStack.setPadding(UIEdgeInsets(inset: 16))
    }

    var accountItemCell: AccountItemCell = .email

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag() // Force rx disposal on reuse
    }

    func setType(_ type: EmailCellType, item: AccountItemCell) {
        accountItemCell = item
        typeSubject.onNext(type)
    }

    private lazy var wrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.makeRoundCorners(corners: [.bottomLeft, .bottomRight], radius: 8)
        return view
    }()

    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            viewEmail, viewDescription, viewConfirm,
        ])
        stack.spacing = 16
        stack.axis = .vertical
        return stack
    }()

    private lazy var viewEmail: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            iconView, leftLabel, rightButton,
        ])
        stack.axis = .horizontal
        stack.spacing = 4
        return stack
    }()

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: ImagesAsset.protocolFailed)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.makeHeightAnchor(equalTo: 18)
        imageView.makeWidthAnchor(equalTo: 18)
        imageView.setImageColor(color: UIColor.unconfirmedYellow)
        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return imageView
    }()

    private lazy var leftLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = TextsAsset.email
        lbl.font = UIFont.bold(size: 16)
        lbl.textAlignment = .left
        lbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return lbl
    }()

    private lazy var rightButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(TextsAsset.Account.addEmail, for: .normal)
        btn.titleLabel?.font = UIFont.text(size: 16)
        btn.titleLabel?.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        btn.titleLabel?.textAlignment = .right
        btn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        return btn
    }()

    ///
    private lazy var viewDescription: UIView = {
        let view = UIView()
        view.addSubview(lblContent)
        lblContent.fillSuperview(padding: UIEdgeInsets(inset: 16))
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var lblContent: UILabel = {
        let label = UILabel()
        label.text = TextsAsset.Account.addEmailDescription
        label.font = UIFont.text(size: 14)
        label.numberOfLines = 0
        return label
    }()

    ///
    private lazy var viewConfirm: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            confirmLabel, UIView(), resendEmailButton,
        ])
        stack.axis = .horizontal
        stack.addSubview(confirmWrapper)
        stack.setPadding(UIEdgeInsets(inset: 16))
        stack.anchor(height: 46)
        confirmWrapper.sendToBack()
        confirmWrapper.fillSuperview()
        return stack
    }()

    private lazy var confirmWrapper: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var confirmLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = TextsAsset.EmailView.infoPro
        label.font = UIFont.text(size: 14)
        return label
    }()

    private lazy var resendEmailButton: UIButton = {
        let resendEmailButton = UIButton()
        resendEmailButton.translatesAutoresizingMaskIntoConstraints = false
        resendEmailButton.setTitle(TextsAsset.Account.resend, for: .normal)
        resendEmailButton.addTarget(self, action: #selector(resendEmailButtonTapped(_:)), for: .touchUpInside)
        resendEmailButton.titleLabel?.font = UIFont.bold(size: 14)
        return resendEmailButton
    }()

    @objc func resendEmailButtonTapped(_: UIButton) {
        resendEmailAction?()
    }

    var resendEmailAction: (() -> Void)?

    @objc func buttonAction() {
        delegate?.addEmailButtonTapped(indexPath: indexPath)
    }

    func bindView(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.wrapperView.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
            self.rightButton.setTitleColor(ThemeUtils.primaryTextColor(isDarkMode: $0), for: .normal)
            self.viewDescription.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: $0)
            self.lblContent.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
            self.confirmWrapper.backgroundColor = ThemeUtils.getEmailTextColor(isDarkMode: $0)
            self.confirmLabel.textColor = ThemeUtils.getConfirmLabelColor(isDarkMode: $0)
            self.resendEmailButton.setTitleColor(ThemeUtils.getConfirmLabelColor(isDarkMode: $0), for: .normal)
        }).disposed(by: disposeBag)

        Observable.combineLatest(typeSubject.asObservable(), isDarkMode.asObservable()).bind { type, isDarkMode in
            self.updateUI(type: type, isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
    }
}

extension AccountEmailCell {
    func updateUI(type: EmailCellType, isDarkMode: Bool) {
        switch type {
        case .confirmEmail:
            viewConfirm.isHidden = false
            viewDescription.isHidden = true
            iconView.isHidden = false
            rightButton.setAttributedTitle(accountItemCell.value, for: .normal)
            leftLabel.text = accountItemCell.title
            rightButton.titleLabel?.textColor = isDarkMode ? .unconfirmedYellow(opacity: 0.5) : .pumpkinOrangeWithOpacity(opacity: 0.5)
            leftLabel.textColor = ThemeUtils.getConfirmLabelColor(isDarkMode: isDarkMode)
        case .email:
            viewConfirm.isHidden = true
            viewDescription.isHidden = true
            leftLabel.text = accountItemCell.title
            rightButton.setAttributedTitle(accountItemCell.value, for: .normal)
            iconView.isHidden = true
        case .emptyEmail:
            viewConfirm.isHidden = true
            viewDescription.isHidden = false
            iconView.isHidden = false
            rightButton.setAttributedTitle(accountItemCell.value, for: .normal)
        case .emailPro:
            viewConfirm.isHidden = true
            viewDescription.isHidden = true
            leftLabel.text = accountItemCell.title
            rightButton.setAttributedTitle(accountItemCell.value, for: .normal)
            iconView.isHidden = true
        }

        iconView.setImageColor(color: type.color(isDarkMode: isDarkMode))
        rightButton.titleLabel?.textColor = type.color(isDarkMode: isDarkMode).withAlphaComponent(0.5)
        leftLabel.textColor = type.color(isDarkMode: isDarkMode)
    }
}
