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
    var showShareSheet: Bool { get set }

    func shareLog()
}

final class DebugLogViewModelImpl: DebugLogViewModel {
    @Published var logContent: String = ""
    @Published var showProgress: Bool = false
    @Published var isDarkMode: Bool = false
    @Published var fontSize: CGFloat = 10
    @Published var hasLoaded = false
    @Published var showShareSheet: Bool = false

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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }

    func loadLog() {
        guard !hasLoaded else { return }
        hasLoaded = true

        showProgress = true

        Task {
            do {
                let content = try await logger.getLogData()
                await MainActor.run {
                    self.logContent = content
                    self.showProgress = false
                }
            } catch {
                await MainActor.run {
                    self.showProgress = false
                }
            }
        }
    }

    func shareLog() {
        self.showShareSheet = true
    }
}
