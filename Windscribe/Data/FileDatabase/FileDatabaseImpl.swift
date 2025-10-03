//
//  FileDatabaseImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

class FileDatabaseImpl: FileDatabase {
    private let logger: FileLogger
    init(logger: FileLogger) {
        self.logger = logger
    }

    func removeFile(path: String) async throws {
        let fileManager = FileManager.default
        do {
            #if os(iOS)
                let documentDirectory = try fileManager.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
            #else
                let documentDirectory = try fileManager.url(for: .cachesDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
            #endif

            let fileURL = documentDirectory.appendingPathComponent(path)
            try fileManager.removeItem(at: fileURL)
        } catch {
            logger.logE("FileDatabaseImpl", "Failed to remove file at path \(path): \(error.localizedDescription)")
            throw FileDatabaseError.deleteError(error.localizedDescription)
        }
    }

    func saveFile(data: Data, path: String) async throws {
        let fileManager = FileManager.default
        do {
            #if os(iOS)
                let documentDirectory = try fileManager.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
            #else
                let documentDirectory = try fileManager.url(for: .cachesDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
            #endif

            let fileURL = documentDirectory.appendingPathComponent(path)
            try data.write(to: fileURL)
        } catch {
            logger.logE("FileDatabaseImpl", "Failed to save file at path \(path): \(error.localizedDescription)")
            throw FileDatabaseError.writeError(error.localizedDescription)
        }
    }

    func readFile(path: String) async throws -> Data {
        let fileManager = FileManager.default
        do {
            #if os(iOS)
                let documentDirectory = try fileManager.url(for: .documentDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
            #else
                let documentDirectory = try fileManager.url(for: .cachesDirectory,
                                                            in: .userDomainMask,
                                                            appropriateFor: nil,
                                                            create: false)
            #endif

            let fileURL = documentDirectory.appendingPathComponent(path)
            return try Data(contentsOf: fileURL, options: .uncached)
        } catch {
            logger.logE("FileDatabaseImpl", "Failed to read file at path \(path): \(error.localizedDescription)")
            if (error as NSError).domain == NSCocoaErrorDomain && (error as NSError).code == NSFileReadNoSuchFileError {
                throw FileDatabaseError.fileNotFound(path)
            } else {
                throw FileDatabaseError.writeError(error.localizedDescription)
            }
        }
    }
}
