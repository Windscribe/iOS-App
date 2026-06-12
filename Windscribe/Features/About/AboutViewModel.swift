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
    var entries: [AboutItemType] = [
        .status, .aboutUs, .privacyPolicy, .terms,
        .blog, .jobs, .softwareLicenses, .changelog
    ]
    var safariURL: URL?

    // MARK: - Actions (called by the view)

    func entrySelected(_ entry: AboutItemType) {
        safariURL = URL(string: entry.url)
    }
}
