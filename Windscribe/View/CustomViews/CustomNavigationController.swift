//
//  CustomNavigationController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-07-11.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class CustomNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.barTintColor = UIColor.midnight
        navigationBar.tintColor = UIColor.white
        navigationBar.isTranslucent = true
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.Bold(size: 24)]

        navigationItem.backBarButtonItem?.title = ""
        navigationBar.backIndicatorImage = UIImage(named: UIConstants.Images.PrefBackIcon)
        navigationBar.backIndicatorTransitionMaskImage = UIImage(named: UIConstants.Images.PrefBackIcon)
    }
}
