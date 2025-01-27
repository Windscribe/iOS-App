//
//  BasePopupViewModel.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 13/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol BasePopupViewModelType {
    var type: PopupTypes? { get }

    func setPopupType(with type: PopupTypes)
    func actionButtonPressed()
}

class BasePopupViewModel: BasePopupViewModelType {
    var type: PopupTypes?

    func setPopupType(with type: PopupTypes) {
        self.type = type
    }

    func actionButtonPressed() {}
}
