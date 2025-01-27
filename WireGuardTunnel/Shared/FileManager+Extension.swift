// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import Foundation
import os.log

extension FileManager {
    static var appGroupId: String? {
        #if os(iOS) || os(tvOS)
            let appGroupIdInfoDictionaryKey = SharedKeys.sharedGroup
        #elseif os(macOS)
            let appGroupIdInfoDictionaryKey = SharedKeys.sharedGroup
        #else
            #error("Unimplemented")
        #endif
        return Bundle.main.object(forInfoDictionaryKey: appGroupIdInfoDictionaryKey) as? String
    }

    private static var sharedFolderURL: URL? {
        guard let sharedFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedKeys.sharedGroup) else {
            return nil
        }
        return sharedFolderURL
    }

    static var logFileURL: URL? {
        return sharedFolderURL?.appendingPathComponent("tunnel-log.bin")
    }

    static var networkExtensionLastErrorFileURL: URL? {
        return sharedFolderURL?.appendingPathComponent("last-error.txt")
    }

    static var loginHelperTimestampURL: URL? {
        return sharedFolderURL?.appendingPathComponent("login-helper-timestamp.bin")
    }

    static func deleteFile(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            return false
        }
        return true
    }
}
