//
//  LookAndFeelSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol LookAndFeelSettingsViewModel: ObservableObject { }

final class LookAndFeelSettingsViewModelImpl: LookAndFeelSettingsViewModel {
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger) {
        self.logger = logger

        bind()
    }

    func bind() {
        // TODO: Bind
    }
}
