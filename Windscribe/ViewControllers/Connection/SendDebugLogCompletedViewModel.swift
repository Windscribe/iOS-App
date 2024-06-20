//
//  SendDebugLogCompletedViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol SendDebugLogCompletedViewModelType {
    var isDarkMode: BehaviorSubject<Bool> {get}
}

class SendDebugLogCompletedViewModel: SendDebugLogCompletedViewModelType {
    let isDarkMode: BehaviorSubject<Bool>

    init(themeManager: ThemeManager) {
        isDarkMode = themeManager.darkTheme
    }
}
