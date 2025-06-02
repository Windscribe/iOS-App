//
//  DebugLogViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol DebugLogViewModel: ObservableObject {
    var title: String { get }
    var logContent: String { get }
    var showProgress: Bool { get }
    var isDarkMode: Bool { get }
    var fontSize: CGFloat { get set }
}

final class DebugLogViewModelImpl: DebugLogViewModel {
    @Published var logContent: String = ""
    @Published var showProgress: Bool = false
    @Published var isDarkMode: Bool = false
    @Published var fontSize: CGFloat = 10
    @Published var hasLoaded = false

    let title = TextsAsset.Debug.viewLog

    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger, lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("DebugLogViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)
    }

    func loadLog() {
        guard !hasLoaded else { return }
        hasLoaded = true

        showProgress = true

        logger.getLogData()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] _ in
                self?.showProgress = false
            }, receiveValue: { [weak self] content in
                self?.logContent = content
            })
            .store(in: &cancellables)
    }
}
