//
//  BackgroundFileManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

protocol BackgroundFileManaging {
    func saveImageFile(from sourceURL: URL, for domain: BackgroundAssetDomainType, completion: @escaping (URL?) -> Void)
    func getImageURL(for domain: BackgroundAssetDomainType) -> URL?
}

final class BackgroundFileManager: BackgroundFileManaging {
    let logger: FileLogger

    init(logger: FileLogger) {
        self.logger = logger
    }

    private func appStorageDirectory() -> URL? {
        return try? FileManager.default.url(for: .applicationSupportDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: true)
    }

    private func fileName(for domain: BackgroundAssetDomainType, originalExtension: String) -> String {
        switch domain {
        case .connect:
            "customBackground_connect.\(originalExtension)"
        case .disconnect:
            "customBackground_disconnect.\(originalExtension)"
        case .aspectRatio:
            ""
        }
    }

    func saveImageFile(from sourceURL: URL, for domain: BackgroundAssetDomainType, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let destinationDir = self.appStorageDirectory() else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let ext = sourceURL.pathExtension.lowercased()
            let fileName = self.fileName(for: domain, originalExtension: ext)
            let destinationURL = destinationDir.appendingPathComponent(fileName)

            let accessGranted = sourceURL.startAccessingSecurityScopedResource()
            defer { if accessGranted { sourceURL.stopAccessingSecurityScopedResource() } }

            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }

                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

                DispatchQueue.main.async {
                    completion(destinationURL)
                }
            } catch {
                self.logger.logE("SoundFileManager", "CopyItem error: \(error)")

                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    func getImageURL(for domain: BackgroundAssetDomainType) -> URL? {
        guard let dir = appStorageDirectory() else { return nil }

        let possibleExtensions = ["jpg", "jpeg", "png", "svg", "tiff", "pdf"]

        for ext in possibleExtensions {
            let fileName = fileName(for: domain, originalExtension: ext)
            let fileURL = dir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                return fileURL
            }
        }
        return nil
    }
}
