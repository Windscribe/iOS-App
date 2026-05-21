//
//  LanguagesObserving.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@preconcurrency import Combine

protocol LanguageStoring: Sendable {
    var activeLanguage: Languages? { get }

    var languageUpdates: AsyncStream<Languages> { get }

    func setActiveLanguage(language: Languages)
}

/// Adapter wrapping the legacy `LanguageManager`.
final class LegacyLanguageStore: LanguageStoring, Sendable {
    private let legacy: LanguageManager

    init(legacy: LanguageManager) {
        self.legacy = legacy
    }

    var activeLanguage: Languages? { legacy.getCurrentLanguage() }

    var languageUpdates: AsyncStream<Languages> {
        let subject = legacy.activelanguage
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    func setActiveLanguage(language: Languages) {
        legacy.setLanguage(language: language)
    }
}
