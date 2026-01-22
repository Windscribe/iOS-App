//
//  UIButton+Extension.swift
//  Windscribe
//
//  Created by Andre Fonseca on 21/01/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import UIKit
import Combine

extension UIButton {
    var tap: UIControlPublisher {
        publisher(for: .touchUpInside)
    }
    var wasSelected: UIControlPublisher {
        publisher(for: .primaryActionTriggered)
    }
}
