//
//  UpgradeButton.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import Swinject

class UpgradeButton: UIButton {
    let dataLeft = UILabel()
    let upgrade = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    func setupButton() {
        // Make the button round
        self.layer.cornerRadius = self.frame.height/2
        self.clipsToBounds = true

        self.setTitle(nil, for: .normal)
        self.isUserInteractionEnabled = true

        self.setBackgroundImage(UIImage.imageWithColor(.whiteWithOpacity(opacity: 0.24)), for: .focused)
        self.setBackgroundImage(UIImage.imageWithColor(.clear), for: .normal)
        let divider = UIView()
        divider.backgroundColor = .whiteWithOpacity(opacity: 0.24)
        divider.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(divider)

        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: 2),
            divider.heightAnchor.constraint(equalToConstant: 50),
            divider.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            divider.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])

        dataLeft.text = "10 GB LEFT"
        dataLeft.font = UIFont.bold(size: 24)
        dataLeft.translatesAutoresizingMaskIntoConstraints = false
        dataLeft.textColor = .seaGreen
        self.addSubview(dataLeft)

        NSLayoutConstraint.activate([
            dataLeft.heightAnchor.constraint(equalToConstant: 50),
            dataLeft.leftAnchor.constraint(equalTo: leftAnchor,
                                           constant: 35),
            dataLeft.rightAnchor.constraint(equalTo: divider.leftAnchor,
                                            constant: -10),
            dataLeft.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])

        upgrade.text = TextsAsset.upgrade.uppercased()
        upgrade.font = UIFont.bold(size: 24)
        upgrade.translatesAutoresizingMaskIntoConstraints = false
        upgrade.textColor = .white
        upgrade.textAlignment = .center
        self.addSubview(upgrade)

        NSLayoutConstraint.activate([
            upgrade.heightAnchor.constraint(equalToConstant: 50),
            upgrade.rightAnchor.constraint(equalTo: rightAnchor,
                                           constant: -10),
            upgrade.leftAnchor.constraint(equalTo: divider.rightAnchor,
                                          constant: 10),
            upgrade.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])

        setborder()
    }

    func setborder() {
            self.layer.borderWidth = 2
            self.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
    }

    func updateText() {
        upgrade.text = TextsAsset.upgrade
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self {
            self.layer.borderColor = UIColor.clear.cgColor
        } else {
            self.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        }
    }
}
