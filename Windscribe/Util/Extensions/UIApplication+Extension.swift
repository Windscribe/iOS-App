//
//  UIApplication+Extension.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import Foundation

extension UIApplication {
    var windowCount: Int {
        let windowScenes = self.connectedScenes.compactMap { $0 as? UIWindowScene }
        let allWindows = windowScenes.flatMap { $0.windows }
        return allWindows.count
    }
}

extension UIApplication: OpensURlType {}
