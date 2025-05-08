//
//  RoutedHostingController.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

class RoutedHostingController<Content: View>: UIHostingController<Content> {
    var onPop: (() -> Void)?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            onPop?()
        }
    }
}
