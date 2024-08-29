//
//  FileUtil.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
class FileDatabaseImpl: FileDatabase {
    private let logger: FileLogger
    init(logger: FileLogger) {
        self.logger = logger
    }
    func removeFile(path: String) {
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
        } catch let error {
            logger.logE(self, "\(error.localizedDescription)")
        }
    }

    func saveFile(data: Data, path: String) {
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
        } catch let error {
            logger.logE(self, "\(error.localizedDescription)")
        }
    }

    func readFile(path: String) -> Data? {
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
        } catch let error {
            logger.logE(self, "\(error.localizedDescription)")
        }
        return nil
    }
}
