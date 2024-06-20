//
//	AccountConfirmEmailCell.swift
//	Windscribe
//
//	Created by Thomas on 21/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

class AccountConfirmEmailCell: UITableViewCell {

    lazy var wrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.unconfirmedYellow
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 8
        return view
    }()

    lazy var titleLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = TextsAsset.Account.confirmYourEmail
        label.font = UIFont.text(size: 16)
        label.textColor = UIColor.midnight
        return label
    }()

    lazy var resendEmailButton: UIButton = {
        let resendEmailButton = UIButton()
        resendEmailButton.translatesAutoresizingMaskIntoConstraints = false
        resendEmailButton.setTitle(TextsAsset.Account.resend, for: .normal)
        resendEmailButton.addTarget(self, action: #selector(resendEmailButtonTapped(_:)), for: .touchUpInside)
        resendEmailButton.setTitleColor(UIColor.midnight, for: .normal)
        resendEmailButton.layer.opacity = 0.5
        resendEmailButton.titleLabel?.font = UIFont.text(size: 16)
        return resendEmailButton
    }()

    @objc func resendEmailButtonTapped(_ sender: UIButton) {
        resendEmailAction?()
    }

    var resendEmailAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(wrapperView)
        wrapperView.makeTopAnchor(constant: 8)
        wrapperView.makeLeadingAnchor()
        wrapperView.makeTrailingAnchor()
        wrapperView.makeBottomAnchor()

        wrapperView.addSubview(titleLbl)
        titleLbl.makeTopAnchor(constant: 16)
        titleLbl.makeLeadingAnchor(constant: 16)
        titleLbl.makeBottomAnchor(constant: 16)

        wrapperView.addSubview(resendEmailButton)
        resendEmailButton.centerYAnchor.constraint(equalTo: titleLbl.centerYAnchor).isActive = true
        resendEmailButton.makeTrailingAnchor(constant: 16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
