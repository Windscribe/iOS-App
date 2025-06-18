//
//  ServerListCollectionViewCell.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 15/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class ServerListCollectionViewCell: UICollectionViewCell {
    @IBOutlet var countryCode: UILabel!
    @IBOutlet var flagImage: UIImageView!
    var isShadow: Bool = true

    func setup(isShadow: Bool) {
        self.isShadow = isShadow
        if isShadow {
            flagImage.layer.masksToBounds = false
            flagImage.layer.shadowColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
            flagImage.layer.shadowOpacity = 1
            flagImage.layer.shadowOffset = CGSize(width: 10, height: 10)
            flagImage.layer.shadowRadius = 0.0
        } else {
            flagImage.layer.shadowColor = UIColor.clear.cgColor
        }
        countryCode.font = .bold(size: 30)
        countryCode.text = countryCode.text?.uppercased()
    }

    override func didUpdateFocus(in _: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if isFocused {
            flagImage.alpha = 1.0
            flagImage.layer.shadowColor = isShadow ? UIColor.white.cgColor : UIColor.clear.cgColor
            countryCode.textColor = .white
        } else {
            flagImage.alpha = 0.40
            flagImage.layer.shadowColor = isShadow ? UIColor.whiteWithOpacity(opacity: 0.24).cgColor : UIColor.clear.cgColor
            countryCode.textColor = .whiteWithOpacity(opacity: 0.40)
        }
    }
}
