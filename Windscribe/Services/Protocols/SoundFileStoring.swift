//
//  SoundFileStoring.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-05-26.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Async/await surface for sound file operations. The Neo-side contract used
/// by feature modules; back this with an adapter over the legacy
/// `SoundFileManaging` (completion-based) until it migrates.
///
/// Sendable since it crosses isolation boundaries.
protocol SoundFileStoring: Sendable {
    /// Saves a sound file from the picker to app storage.
    /// - Parameters:
    ///   - sourceURL: The URL from the document picker
    ///   - domain: Connect or disconnect domain
    /// - Returns: The destination URL if successful, nil otherwise
    func saveSoundFile(from sourceURL: URL, for domain: SoundAssetDomainType) async -> URL?

    /// Retrieves the URL for a saved custom sound file.
    /// - Parameter domain: Connect or disconnect domain
    /// - Returns: The file URL if it exists, nil otherwise
    func getSoundURL(for domain: SoundAssetDomainType) -> URL?
}

/// Adapter that wraps the legacy `SoundFileManaging` (completion-based)
/// and exposes the Neo `SoundFileStoring` surface (async/await).
///
/// Lives at the Neo composition seam: created in
/// `Windscribe/App/Environment+Dependencies.swift`, never inside a feature module.
final class LegacySoundFileStore: SoundFileStoring, Sendable {
    private let legacy: SoundFileManaging

    init(legacy: SoundFileManaging) {
        self.legacy = legacy
    }

    func saveSoundFile(from sourceURL: URL, for domain: SoundAssetDomainType) async -> URL? {
        await withCheckedContinuation { continuation in
            legacy.saveSoundFile(from: sourceURL, for: domain) { url in
                continuation.resume(returning: url)
            }
        }
    }

    func getSoundURL(for domain: SoundAssetDomainType) -> URL? {
        legacy.getSoundURL(for: domain)
    }
}
