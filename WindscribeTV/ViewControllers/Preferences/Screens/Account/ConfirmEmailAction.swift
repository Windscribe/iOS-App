//
//  ConfirmEmailViewControllerDelegate.swift
//  Windscribe
//
//  Created by Andre Fonseca on 13/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum ConfirmEmailAction {
    case dismiss
    case enterEmail
}

protocol ConfirmEmailViewControllerDelegate: AnyObject {
    func dismissWith(action: ConfirmEmailAction)
}
