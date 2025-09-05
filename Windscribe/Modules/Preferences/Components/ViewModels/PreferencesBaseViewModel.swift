//
//  PreferencesBaseViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 05/09/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol PreferencesBaseViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    func actionSelected()
    func reloadItems()
    func bindSubjects()
    func actionSelected(_ action: MenuEntryActionResponseType)
}

class PreferencesBaseViewModelImpl: PreferencesBaseViewModel {
    @Published var isDarkMode: Bool = false

    var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies
    let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let hapticFeedbackManager: HapticFeedbackManager

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.hapticFeedbackManager = hapticFeedbackManager

        reloadItems()
        bindSubjects()
    }

    func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("PreferencesBaseViewModelImpl", "Theme Adjustment Change error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
                self?.reloadItems()
            })
            .store(in: &cancellables)
    }

    func actionSelected() {
        hapticFeedbackManager.run(level: .medium)
    }

    func actionSelected(_ action: MenuEntryActionResponseType) {
        if case .toggle = action {
            actionSelected()
        }
    }

    /// Needs To Be Overriden
    func reloadItems() { }
}
