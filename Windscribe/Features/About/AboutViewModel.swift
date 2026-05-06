//
//  AboutViewModel.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class AboutViewModel {

    // MARK: - State (read by the view)

    var isDarkMode: Bool
    var entries: [AboutItemType] = [
        .status, .aboutUs, .privacyPolicy, .terms,
        .blog, .jobs, .softwareLicenses, .changelog
    ]
    var safariURL: URL?

    // MARK: - Dependencies (injected via init — protocols only)

    private let lookAndFeel: any LookAndFeelObserving

    // MARK: - Init

    init(lookAndFeel: any LookAndFeelObserving) {
        self.lookAndFeel = lookAndFeel
        self.isDarkMode = lookAndFeel.isDarkMode
    }

    // MARK: - Actions (called by the view)

    func entrySelected(_ entry: AboutItemType) {
        safariURL = URL(string: entry.url)
    }

    /// Long-running observation of dark-mode updates. The view drives this
    /// via `.task { await viewModel.observeDarkMode() }`, so it auto-cancels
    /// on disappearance — no manual `cancellables` to manage.
    func observeDarkMode() async {
        for await isDark in lookAndFeel.darkModeUpdates {
            isDarkMode = isDark
        }
    }
}
