//
//  ShakeForDataPopupViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ShakeForDataPopupViewModelType {
    func wasShown()
}

class ShakeForDataPopupViewModel: ShakeForDataPopupViewModelType {
    var logger: FileLogger

    init(logger: FileLogger) {
        self.logger = logger
    }

    func wasShown() {
        logger.logD("ShakeForDataPopupViewModel", "Displaying Shake For Data Popup View")
    }
}
