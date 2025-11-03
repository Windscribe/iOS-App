//
//  AboutSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol AboutSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var entries: [AboutItemType] { get set }
    var safariURL: URL? { get }

    func entrySelected(_ entry: AboutItemType)
}

final class AboutSettingsViewModelImpl: AboutSettingsViewModel {
    @Published var isDarkMode: Bool = false
    @Published var entries: [AboutItemType] = []
    @Published var safariURL: URL?

    // MARK: - Dependencies
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository

        bindSubjects()
        reloadItems()
    }

    func entrySelected(_ entry: AboutItemType) {
        safariURL = URL(string: entry.url)
    }

    private func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
                self?.reloadItems()
            }
            .store(in: &cancellables)
    }

    private func reloadItems() {
        entries = [.status, .aboutUs, .privacyPolicy, .terms, .blog, .jobs, .softwareLicenses, .changelog]
    }
}
