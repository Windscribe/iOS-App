//
//  ViewLogViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-25.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ViewLogViewModel {
    var title: String { get }
    var logContent: CurrentValueSubject<String, Never> { get }
    var showProgress: CurrentValueSubject<Bool, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
}

class ViewLogViewModelImpl: ViewLogViewModel {
    let title = TextsAsset.Debug.viewLog
    let logContent = CurrentValueSubject<String, Never>("")
    let showProgress = CurrentValueSubject<Bool, Never>(false)
    let isDarkMode: CurrentValueSubject<Bool, Never>
    private let logger: FileLogger

    init(logger: FileLogger, lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.logger = logger
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        load()
    }

    private func load() {
        showProgress.send(true)
        Task {
            do {
                let content = try await logger.getLogData()
                await MainActor.run {
                    self.showProgress.send(false)
                    self.logContent.send(content)
                }
            } catch {
                await MainActor.run {
                    self.showProgress.send(false)
                }
            }
        }
    }
}
