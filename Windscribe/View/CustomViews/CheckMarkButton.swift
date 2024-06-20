//
//  CheckMarkButton.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class CheckMarkButton: SwitchButton {
    override init(isDarkMode: BehaviorSubject<Bool>) {
        super.init(isDarkMode: isDarkMode)
        self.onImage =  UIImage(named: ImagesAsset.CheckMarkButton.on)!
        self.offImage = UIImage(named: ImagesAsset.CheckMarkButton.off)!
        self.setStatus(false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
