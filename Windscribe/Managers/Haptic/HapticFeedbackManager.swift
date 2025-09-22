//
//  HapticFeedbackGenerator.swift
//  Windscribe
//
//  Created by Yalcin on 2020-09-10.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import Swinject
import UIKit

protocol HapticFeedbackManager {
    func run(level: UIImpactFeedbackGenerator.FeedbackStyle)
}

class HapticFeedbackManagerImpl: HapticFeedbackManager {
    private let disposeBag = DisposeBag()
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

    func run(level: UIImpactFeedbackGenerator.FeedbackStyle) {
        if hapticFeedback {
            let hapticFeedbackgenerator = UIImpactFeedbackGenerator(style: level)
            hapticFeedbackgenerator.prepare()
            hapticFeedbackgenerator.impactOccurred()
        }
    }
}
