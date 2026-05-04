//
//  MockFileDatabase.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-09-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

final class MockFileDatabase: FileDatabase, @unchecked Sendable {
    private let lock = NSLock()

    // In-memory storage for testing (lock-protected for thread-safety)
    private var _fileStorage: [String: Data] = [:]

    // Test configuration flags
    var shouldThrowOnRead = false
    var shouldThrowOnSave = false
    var shouldThrowOnRemove = false
    var customReadError: Error?
    var customSaveError: Error?
    var customRemoveError: Error?

    // Call tracking properties
    var readFileCalled = false
    var saveFileCalled = false
    var removeFileCalled = false
    var lastReadFilePath: String?
    var lastSavedFilePath: String?
    var lastSavedFileData: Data?
    var lastRemovedFilePath: String?

    // Mock data for testing
    var mockFileContent: Data?

    init() {}

    func readFile(path: String) async throws -> Data {
        lock.lock()
        defer { lock.unlock() }

        readFileCalled = true
        lastReadFilePath = path

        if shouldThrowOnRead {
            throw customReadError ?? FileDatabaseError.writeError("Mock read error")
        }

        // If mockFileContent is set, return it (for test scenarios)
        if let mockData = mockFileContent {
            return mockData
        }

        guard let data = _fileStorage[path] else {
            throw FileDatabaseError.fileNotFound(path)
        }

        return data
    }

    func saveFile(data: Data, path: String) async throws {
        lock.lock()
        defer { lock.unlock() }

        saveFileCalled = true
        lastSavedFilePath = path
        lastSavedFileData = data

        if shouldThrowOnSave {
            throw customSaveError ?? FileDatabaseError.writeError("Mock save error")
        }

        _fileStorage[path] = data
    }

    func removeFile(path: String) async throws {
        lock.lock()
        defer { lock.unlock() }

        removeFileCalled = true
        lastRemovedFilePath = path

        if shouldThrowOnRemove {
            throw customRemoveError ?? FileDatabaseError.deleteError("Mock remove error")
        }

        _fileStorage.removeValue(forKey: path)
    }

    // Test helper methods
    func reset() {
        _fileStorage.removeAll()
        shouldThrowOnRead = false
        shouldThrowOnSave = false
        shouldThrowOnRemove = false
        customReadError = nil
        customSaveError = nil
        customRemoveError = nil

        // Reset tracking properties
        readFileCalled = false
        saveFileCalled = false
        removeFileCalled = false
        lastReadFilePath = nil
        lastSavedFilePath = nil
        lastSavedFileData = nil
        lastRemovedFilePath = nil
        mockFileContent = nil
    }

    func fileExists(path: String) -> Bool {
        return _fileStorage[path] != nil
    }

    func getAllFiles() -> [String: Data] {
        return _fileStorage
    }

    func getFileCount() -> Int {
        return _fileStorage.count
    }
}
