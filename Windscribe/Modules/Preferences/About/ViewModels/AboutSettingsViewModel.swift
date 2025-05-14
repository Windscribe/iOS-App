//
//  AboutSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum AboutItemType: String {
    case status
    case aboutUs
    case privacyPolicy
    case terms
    case blog
    case jobs
    case softwareLicenses
    case changelog

    var title: String {
        switch self {
        case .status:
            return TextsAsset.About.status
        case .aboutUs:
            return TextsAsset.About.aboutUs
        case .privacyPolicy:
            return TextsAsset.About.privacyPolicy
        case .terms:
            return TextsAsset.About.terms
        case .blog:
            return TextsAsset.About.blog
        case .softwareLicenses:
            return TextsAsset.About.softwareLicenses
        case .jobs:
            return TextsAsset.About.jobs
        case .changelog:
            return TextsAsset.About.changelog
        }
    }

    var url: String {
        switch self {
        case .status:
            return Links.status
        case .aboutUs:
            return Links.about
        case .privacyPolicy:
            return Links.privacy
        case .terms:
            return Links.termsWindscribe
        case .blog:
            return Links.blog
        case .jobs:
            return Links.jobs
        case .softwareLicenses:
            return Links.softwareLicenses
        case .changelog:
            return Links.changelog
        }
    }
}

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
        safariURL =  URL(string: LinkProvider.getWindscribeLink(path: entry.url))
    }
}
