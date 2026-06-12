//
//  BackgroundFileStoring.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-05-26.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Async/await surface for background image file operations. The Neo-side
/// contract used by feature modules; back this with an adapter over the legacy
/// `BackgroundFileManaging` (completion-based) until it migrates.
///
/// Sendable since it crosses isolation boundaries.
protocol BackgroundFileStoring: Sendable {
    /// Saves an image file from the picker to app storage.
    /// - Parameters:
    ///   - sourceURL: The URL from the document picker
    ///   - domain: Connect or disconnect domain
    /// - Returns: The destination URL if successful, nil otherwise
    func saveImageFile(from sourceURL: URL, for domain: BackgroundAssetDomainType) async -> URL?

    /// Retrieves the URL for a saved custom background image.
    /// - Parameter domain: Connect or disconnect domain
    /// - Returns: The file URL if it exists, nil otherwise
    func getImageURL(for domain: BackgroundAssetDomainType) -> URL?
}

/// Adapter that wraps the legacy `BackgroundFileManaging` (completion-based)
/// and exposes the Neo `BackgroundFileStoring` surface (async/await).
///
/// Lives at the Neo composition seam: created in
/// `Windscribe/App/Environment+Dependencies.swift`, never inside a feature module.
final class LegacyBackgroundFileStore: BackgroundFileStoring, Sendable {
    private let legacy: BackgroundFileManaging

    init(legacy: BackgroundFileManaging) {
        self.legacy = legacy
    }

    func saveImageFile(from sourceURL: URL, for domain: BackgroundAssetDomainType) async -> URL? {
        await withCheckedContinuation { continuation in
            legacy.saveImageFile(from: sourceURL, for: domain) { url in
                continuation.resume(returning: url)
            }
        }
    }

    func getImageURL(for domain: BackgroundAssetDomainType) -> URL? {
        legacy.getImageURL(for: domain)
    }
}
