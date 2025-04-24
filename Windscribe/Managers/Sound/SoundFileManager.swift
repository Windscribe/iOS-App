//
//  SoundFileManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-24.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import AVFoundation

protocol SoundFileManaging {
    func saveSoundFile(from sourceURL: URL, for domain: SoundAssetDomainType, completion: @escaping (URL?) -> Void)
    func getSoundURL(for domain: SoundAssetDomainType) -> URL?
}

final class SoundFileManager: SoundFileManaging {

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

    private func fileName(for domain: SoundAssetDomainType, originalExtension: String) -> String {
        switch domain {
        case .connect:
            return "customSound_connect.\(originalExtension)"
        case .disconnect:
            return "customSound_disconnect.\(originalExtension)"
        }
    }

    func saveSoundFile(from sourceURL: URL, for domain: SoundAssetDomainType, completion: @escaping (URL?) -> Void) {
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

    func getSoundURL(for domain: SoundAssetDomainType) -> URL? {
        guard let dir = appStorageDirectory() else { return nil }

        let possibleExtensions = ["m4a", "mp3", "wav", "caf", "aiff", "aac"]

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
