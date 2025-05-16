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

    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger) {
        self.logger = logger
        entries = [.status, .aboutUs, .privacyPolicy, .terms, .blog, .jobs, .softwareLicenses, .changelog]
    }

    func entrySelected(_ entry: AboutItemType) {
        safariURL = URL(string: entry.url)
    }
}
