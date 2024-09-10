//
//  ServerListCollectionViewCell.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 15/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class ServerListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var countryCode: UILabel!
    @IBOutlet weak var flagImage: UIImageView!

    override func awakeFromNib() {
       super.awakeFromNib()
    }

    func setup(isShadow: Bool) {
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

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if self.isFocused {
            self.flagImage.alpha = 1.0
            flagImage.layer.shadowColor = UIColor.white.cgColor
            self.countryCode.textColor = .white
        } else {
            self.flagImage.alpha = 0.40
            flagImage.layer.shadowColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
            self.countryCode.textColor = .whiteWithOpacity(opacity: 0.40)
        }
    }
}
