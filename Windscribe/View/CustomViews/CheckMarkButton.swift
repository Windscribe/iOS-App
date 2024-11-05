//
//  CheckMarkButton.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class CheckMarkButton: SwitchButton {
    override init(isDarkMode: BehaviorSubject<Bool>) {
        super.init(isDarkMode: isDarkMode)
        onImage = UIImage(named: ImagesAsset.CheckMarkButton.on)!
        offImage = UIImage(named: ImagesAsset.CheckMarkButton.off)!
        setStatus(false)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
