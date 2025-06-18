//
//  UpgradeButton.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

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
        layer.cornerRadius = frame.height / 2
        clipsToBounds = true

        setTitle(nil, for: .normal)
        isUserInteractionEnabled = true

        setBackgroundImage(UIImage.imageWithColor(.whiteWithOpacity(opacity: 0.24)), for: .focused)
        setBackgroundImage(UIImage.imageWithColor(.clear), for: .normal)
        let divider = UIView()
        divider.backgroundColor = .whiteWithOpacity(opacity: 0.24)
        divider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(divider)

        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: 2),
            divider.heightAnchor.constraint(equalToConstant: 50),
            divider.centerXAnchor.constraint(equalTo: centerXAnchor),
            divider.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        dataLeft.text = "10 GB LEFT"
        dataLeft.font = UIFont.bold(size: 24)
        dataLeft.translatesAutoresizingMaskIntoConstraints = false
        dataLeft.textColor = .seaGreen
        addSubview(dataLeft)

        NSLayoutConstraint.activate([
            dataLeft.heightAnchor.constraint(equalToConstant: 50),
            dataLeft.leftAnchor.constraint(equalTo: leftAnchor,
                                           constant: 35),
            dataLeft.rightAnchor.constraint(equalTo: divider.leftAnchor,
                                            constant: -10),
            dataLeft.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        upgrade.text = TextsAsset.upgrade.uppercased()
        upgrade.font = UIFont.bold(size: 24)
        upgrade.translatesAutoresizingMaskIntoConstraints = false
        upgrade.textColor = .white
        upgrade.textAlignment = .center
        addSubview(upgrade)

        NSLayoutConstraint.activate([
            upgrade.heightAnchor.constraint(equalToConstant: 50),
            upgrade.rightAnchor.constraint(equalTo: rightAnchor,
                                           constant: -10),
            upgrade.leftAnchor.constraint(equalTo: divider.rightAnchor,
                                          constant: 10),
            upgrade.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        setborder()
    }

    func setborder() {
        layer.borderWidth = 2
        layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.50).cgColor
    }

    func updateText() {
        upgrade.text = TextsAsset.upgrade
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if context.nextFocusedView == self {
            layer.borderColor = UIColor.clear.cgColor
        } else {
            layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        }
    }
}
