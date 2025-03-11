//
//  HapticFeedbackGeneratorV2.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-01-24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

protocol HapticFeedbackGeneratorV2 {
    func run(level: UIImpactFeedbackGenerator.FeedbackStyle)
}
