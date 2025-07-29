//
//  MaintananceLocationViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-24.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import SafariServices

protocol MaintananceLocationViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var shouldDismiss: Bool { get }
    var safariURL: URL? { get }

    func cancel()
    func checkStatus()
}

final class MaintananceLocationViewModelImpl: MaintananceLocationViewModel {
    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var safariURL: URL?

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    init(lookAndFeelRepository: LookAndFeelRepositoryType, logger: FileLogger) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("MaintananceLocationViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)
    }

    func cancel() {
        shouldDismiss = true
    }

    func checkStatus() {
        safariURL = URL(string: Links.status)
    }
}
