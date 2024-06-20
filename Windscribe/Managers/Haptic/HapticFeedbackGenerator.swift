//
//  HapticFeedbackGenerator.swift
//  Windscribe
//
//  Created by Yalcin on 2020-09-10.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class HapticFeedbackGenerator: HapticFeedbackGeneratorV2 {
    private let disposeBag = DisposeBag()
    private let preference: Preferences
    private var hapticFeedback = true

    init(preference: Preferences) {
        self.preference = preference
        loadHapticFeedback()
    }

    private func loadHapticFeedback() {
        preference.getHapticFeedback().subscribe(
            onNext: { data in
                self.hapticFeedback = data ?? true
            },onError: { _ in
                self.hapticFeedback = true
            },onCompleted: {
                self.hapticFeedback = true
            }).disposed(by: disposeBag)
    }

    func run(level: UIImpactFeedbackGenerator.FeedbackStyle) {
        if hapticFeedback {
            let hapticFeedbackgenerator = UIImpactFeedbackGenerator(style: level)
            hapticFeedbackgenerator.prepare()
            hapticFeedbackgenerator.impactOccurred()
        }
    }

    // need to delete shared variable
    static let shared = HapticFeedbackGenerator(preference: SharedSecretDefaults.shared)
}
