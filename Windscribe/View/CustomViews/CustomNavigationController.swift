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
        self.navigationBar.barTintColor = UIColor.midnight
        self.navigationBar.tintColor = UIColor.white
        self.navigationBar.isTranslucent = true
        self.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.Bold(size: 24)]

        self.navigationItem.backBarButtonItem?.title = ""
        self.navigationBar.backIndicatorImage = UIImage(named: UIConstants.Images.PrefBackIcon)
        self.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: UIConstants.Images.PrefBackIcon)
    }

}
