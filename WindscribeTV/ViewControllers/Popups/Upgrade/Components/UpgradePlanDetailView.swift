//
//  UpgradePlanDetailView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 14/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class UpgradePlanDetailView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    func setup(with title: String, and body: String) {
        titleLabel.text = title
        bodyLabel.text = body

        titleLabel.font = UIFont.bold(size: 42)
        bodyLabel.font = UIFont.regular(size: 42)
        titleLabel.textColor = .white
        bodyLabel.textColor = .whiteWithOpacity(opacity: 0.6)
    }
}
