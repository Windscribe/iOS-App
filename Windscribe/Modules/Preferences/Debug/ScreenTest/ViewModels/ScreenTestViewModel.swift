//
//  ScreenTestViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-19.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

protocol ScreenTestViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var visibleItems: [ScreenTestItemType] { get set }
    var presentedScreen: ScreenTestRouteID? { get set }

    func runHapticfeedback()
}

final class ScreenTestViewModelImpl: ScreenTestViewModel {
    @Published var isDarkMode: Bool = false
    @Published var visibleItems: [ScreenTestItemType] = []
    @Published var presentedScreen: ScreenTestRouteID?

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager
    private var cancellables = Set<AnyCancellable>()

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager
        bindSubjects()
        reloadItems()
    }

    private func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }

    private func reloadItems() {
        visibleItems = ScreenTestItemType.allCases
    }

    func runHapticfeedback() {
        hapticFeedbackManager.run(level: .medium)
    }
}
