//
//  HapticFeedbackGeneratorV2.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-01-24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol HapticFeedbackGeneratorV2 {
    func run(level: UIImpactFeedbackGenerator.FeedbackStyle)
}
