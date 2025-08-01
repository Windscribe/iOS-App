//
//  LocalizationService.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-01.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

protocol LocalizationService {
    func updateLanguage(_ language: Languages)
    func localizedString(for key: String, comment: String) -> String
}

class LocalizationServiceImpl: LocalizationService {

    private var bundle: Bundle = .main
    private let logger: FileLogger

    init(logger: FileLogger) {
        self.logger = logger
    }

    func updateLanguage(_ language: Languages) {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            bundle = .main

            logger.logD("LocalizationService", "Bundle doesnt have the the seletected language")

            return
        }

        bundle = languageBundle
    }

    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, tableName: nil, bundle: bundle, comment: comment)
    }
}
