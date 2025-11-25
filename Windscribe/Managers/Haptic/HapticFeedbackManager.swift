//
//  HapticFeedbackGenerator.swift
//  Windscribe
//
//  Created by Yalcin on 2020-09-10.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
import UIKit

enum HapticFeedbackLevel {
    case light
    case medium
    case heavy
    case soft
    case rigid
}

protocol HapticFeedbackManager {
    func run(level: HapticFeedbackLevel)
}

class HapticFeedbackManagerImpl: HapticFeedbackManager {
    private let preferences: Preferences
    private let logger: FileLogger
    private var hapticFeedback = true
    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences, logger: FileLogger) {
        self.preferences = preferences
        self.logger = logger
        loadHapticFeedback()
    }

    private func loadHapticFeedback() {
        preferences.getHapticFeedback()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.hapticFeedback = data ?? true
            }
            .store(in: &cancellables)
    }

    func run(level: HapticFeedbackLevel) {
        #if os(iOS)
        if hapticFeedback {
            let style: UIImpactFeedbackGenerator.FeedbackStyle
            switch level {
            case .light:
                style = .light
            case .medium:
                style = .medium
            case .heavy:
                style = .heavy
            case .soft:
                style = .soft
            case .rigid:
                style = .rigid
            }
            let hapticFeedbackgenerator = UIImpactFeedbackGenerator(style: style)
            hapticFeedbackgenerator.prepare()
            hapticFeedbackgenerator.impactOccurred()
        }
        #endif
    }
}
