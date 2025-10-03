//
//  MockFileDatabase.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-09-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

final class MockFileDatabase: FileDatabase {
    // In-memory storage for testing (thread-safe with lock)
    private var _fileStorage: [String: Data] = [:]
    private let lock = NSLock()

    // Test configuration flags
    var shouldThrowOnRead = false
    var shouldThrowOnSave = false
    var shouldThrowOnRemove = false
    var customReadError: Error?
    var customSaveError: Error?
    var customRemoveError: Error?

    func readFile(path: String) async throws -> Data {
        if shouldThrowOnRead {
            throw customReadError ?? FileDatabaseError.writeError("Mock read error")
        }

        lock.lock()
        defer { lock.unlock() }

        guard let data = _fileStorage[path] else {
            throw FileDatabaseError.fileNotFound(path)
        }

        return data
    }

    func saveFile(data: Data, path: String) async throws {
        if shouldThrowOnSave {
            throw customSaveError ?? FileDatabaseError.writeError("Mock save error")
        }

        lock.lock()
        defer { lock.unlock() }
        _fileStorage[path] = data
    }

    func removeFile(path: String) async throws {
        if shouldThrowOnRemove {
            throw customRemoveError ?? FileDatabaseError.deleteError("Mock remove error")
        }

        lock.lock()
        defer { lock.unlock() }
        _fileStorage.removeValue(forKey: path)
    }

    // Test helper methods
    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _fileStorage.removeAll()
        shouldThrowOnRead = false
        shouldThrowOnSave = false
        shouldThrowOnRemove = false
        customReadError = nil
        customSaveError = nil
        customRemoveError = nil
    }

    func fileExists(path: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _fileStorage[path] != nil
    }

    func getAllFiles() -> [String: Data] {
        lock.lock()
        defer { lock.unlock() }
        return _fileStorage
    }

    func getFileCount() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return _fileStorage.count
    }
}
