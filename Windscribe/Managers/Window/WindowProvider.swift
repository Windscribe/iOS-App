//
//  WindowProvider.swift
//  Windscribe
//
//  Created by Anthony on 2026-03-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import UIKit

protocol WindowProvider: AnyObject {
    var mainWindow: UIWindow? { get }
    var shortcutType: ShortcutType { get set }
    var sceneWindow: UIWindow? { get set }
    var pendingURL: URL? { get set }
    var pendingActivityType: String? { get set }
}

class WindowProviderImpl: WindowProvider {
    var sceneWindow: UIWindow?

    var mainWindow: UIWindow? {
        return sceneWindow
    }

    var shortcutType: ShortcutType = .none
    var pendingURL: URL?
    var pendingActivityType: String?
}
