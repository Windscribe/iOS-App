//
//  FileDatabaseTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-09-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class FileDatabaseTests: XCTestCase {

    var mockContainer: Container!
    var fileDatabase: FileDatabase!
    var mockFileDatabase: MockFileDatabase!
    var mockLogger: MockLogger!

    // Test constants
    private let testPath = "test_file.txt"
    private let testPath2 = "test_file2.conf"
    private let testData = "Test file content".data(using: .utf8)!
    private let testEmptyData = Data()
    private let testLargeData = String(repeating: "Large content for testing ", count: 1000).data(using: .utf8)!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockLogger = MockLogger()
        mockFileDatabase = MockFileDatabase()

        // Register mock logger
        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }

        // Register mock FileDatabase for unit tests
        mockContainer.register(FileDatabase.self) { _ in
            return self.mockFileDatabase
        }.inObjectScope(.container)

        fileDatabase = mockContainer.resolve(FileDatabase.self)!
    }

    override func tearDown() {
        mockFileDatabase.reset()
        mockContainer = nil
        fileDatabase = nil
        mockFileDatabase = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: Basic File Operations Tests

    func test_saveFile_shouldStoreFileSuccessfully() async {
        do {
            try await fileDatabase.saveFile(data: testData, path: testPath)

            XCTAssertTrue(mockFileDatabase.fileExists(path: testPath))
            XCTAssertEqual(mockFileDatabase.getFileCount(), 1)
        } catch {
            XCTFail("Expected saveFile to succeed, but got error: \(error)")
        }
    }

    func test_readFile_shouldRetrieveDataSuccessfully() async {
        do {
            // First save a file
            try await fileDatabase.saveFile(data: testData, path: testPath)

            // Then read it back
            let retrievedData = try await fileDatabase.readFile(path: testPath)
            XCTAssertEqual(retrievedData, testData)
        } catch {
            XCTFail("Expected file operations to succeed, but got error: \(error)")
        }
    }

    func test_readFile_nonExistentFile_shouldThrowFileNotFound() async {
        do {
            _ = try await fileDatabase.readFile(path: "non_existent.txt")
            XCTFail("Expected readFile to throw fileNotFound error")
        } catch FileDatabaseError.fileNotFound(let path) {
            XCTAssertEqual(path, "non_existent.txt")
        } catch {
            XCTFail("Expected FileDatabaseError.fileNotFound, but got: \(error)")
        }
    }

    func test_removeFile_shouldDeleteFileSuccessfully() async {
        do {
            // First save a file
            try await fileDatabase.saveFile(data: testData, path: testPath)
            XCTAssertTrue(mockFileDatabase.fileExists(path: testPath))

            // Remove the file
            try await fileDatabase.removeFile(path: testPath)

            // Verify file no longer exists
            XCTAssertFalse(mockFileDatabase.fileExists(path: testPath))
        } catch {
            XCTFail("Expected file operations to succeed, but got error: \(error)")
        }
    }

    func test_removeFile_nonExistentFile_shouldNotThrow() async {
        // Mock doesn't throw for non-existent files (silently succeeds)
        do {
            try await fileDatabase.removeFile(path: "non_existent.txt")
            // Should succeed silently
        } catch {
            XCTFail("Expected removeFile to succeed silently for non-existent file, but got error: \(error)")
        }
    }

    // MARK: File Content Tests

    func test_saveFile_emptyData_shouldSaveAndRetrieve() async {
        do {
            try await fileDatabase.saveFile(data: testEmptyData, path: "empty_file.txt")

            let retrievedData = try await fileDatabase.readFile(path: "empty_file.txt")
            XCTAssertEqual(retrievedData, testEmptyData)
            XCTAssertEqual(retrievedData.count, 0)
        } catch {
            XCTFail("Expected empty file operations to succeed, but got error: \(error)")
        }
    }

    func test_saveFile_largeData_shouldSaveAndRetrieve() async {
        do {
            try await fileDatabase.saveFile(data: testLargeData, path: "large_file.dat")

            let retrievedData = try await fileDatabase.readFile(path: "large_file.dat")
            XCTAssertEqual(retrievedData, testLargeData)
            XCTAssertEqual(retrievedData.count, testLargeData.count)
        } catch {
            XCTFail("Expected large file operations to succeed, but got error: \(error)")
        }
    }

    func test_saveFile_binaryData_shouldSaveAndRetrieve() async {
        let binaryData = Data([0x00, 0xFF, 0x42, 0xAB, 0xCD, 0xEF])

        do {
            try await fileDatabase.saveFile(data: binaryData, path: "binary_file.dat")

            let retrievedData = try await fileDatabase.readFile(path: "binary_file.dat")
            XCTAssertEqual(retrievedData, binaryData)
        } catch {
            XCTFail("Expected binary file operations to succeed, but got error: \(error)")
        }
    }

    // MARK: File Update Tests

    func test_saveFile_existingFile_shouldUpdateContent() async {
        let initialData = "Initial content".data(using: .utf8)!
        let updatedData = "Updated content".data(using: .utf8)!

        do {
            // Save initial content
            try await fileDatabase.saveFile(data: initialData, path: testPath)
            let retrieved1 = try await fileDatabase.readFile(path: testPath)
            XCTAssertEqual(retrieved1, initialData)

            // Update content
            try await fileDatabase.saveFile(data: updatedData, path: testPath)
            let retrieved2 = try await fileDatabase.readFile(path: testPath)
            XCTAssertEqual(retrieved2, updatedData)
            XCTAssertNotEqual(retrieved2, initialData)
        } catch {
            XCTFail("Expected file update operations to succeed, but got error: \(error)")
        }
    }

    // MARK: Multiple Files Tests

    func test_multipleFiles_shouldMaintainSeparateContent() async {
        let data1 = "File 1 content".data(using: .utf8)!
        let data2 = "File 2 content".data(using: .utf8)!

        do {
            // Save two different files
            try await fileDatabase.saveFile(data: data1, path: testPath)
            try await fileDatabase.saveFile(data: data2, path: testPath2)

            // Verify both files have correct content
            let retrieved1 = try await fileDatabase.readFile(path: testPath)
            let retrieved2 = try await fileDatabase.readFile(path: testPath2)

            XCTAssertEqual(retrieved1, data1)
            XCTAssertEqual(retrieved2, data2)
            XCTAssertNotEqual(retrieved1, retrieved2)
            XCTAssertEqual(mockFileDatabase.getFileCount(), 2)
        } catch {
            XCTFail("Expected multiple file operations to succeed, but got error: \(error)")
        }
    }

    func test_removeFile_oneOfMultiple_shouldOnlyRemoveTargetFile() async {
        let data1 = "File 1 content".data(using: .utf8)!
        let data2 = "File 2 content".data(using: .utf8)!

        do {
            // Save two files
            try await fileDatabase.saveFile(data: data1, path: testPath)
            try await fileDatabase.saveFile(data: data2, path: testPath2)
            XCTAssertEqual(mockFileDatabase.getFileCount(), 2)

            // Remove first file
            try await fileDatabase.removeFile(path: testPath)

            // Verify first file is gone
            XCTAssertFalse(mockFileDatabase.fileExists(path: testPath))

            // Verify second file still exists
            XCTAssertTrue(mockFileDatabase.fileExists(path: testPath2))
            let retrieved2 = try await fileDatabase.readFile(path: testPath2)
            XCTAssertEqual(retrieved2, data2)
            XCTAssertEqual(mockFileDatabase.getFileCount(), 1)
        } catch {
            XCTFail("Expected selective file removal to succeed, but got error: \(error)")
        }
    }

    // MARK: VPN Config Files Tests (Real-world scenarios)

    func test_openVPNConfigFile_shouldSaveAndRetrieve() async {
        let openVPNConfig = """
        client
        proto udp
        remote server.example.com 1194
        resolv-retry infinite
        nobind
        persist-key
        persist-tun
        ca ca.crt
        cert client.crt
        key client.key
        cipher AES-256-CBC
        auth SHA256
        """.data(using: .utf8)!

        do {
            try await fileDatabase.saveFile(data: openVPNConfig, path: "config.ovpn")

            let retrievedConfig = try await fileDatabase.readFile(path: "config.ovpn")
            XCTAssertEqual(retrievedConfig, openVPNConfig)

            // Verify content can be converted back to string
            let configString = String(data: retrievedConfig, encoding: .utf8)
            XCTAssertNotNil(configString)
            XCTAssertTrue(configString!.contains("proto udp"))
            XCTAssertTrue(configString!.contains("remote server.example.com"))
        } catch {
            XCTFail("Expected OpenVPN config operations to succeed, but got error: \(error)")
        }
    }

    func test_wireguardConfigFile_shouldSaveAndRetrieve() async {
        let wireguardConfig = """
        [Interface]
        PrivateKey = private_key_here
        Address = 10.0.0.1/32
        DNS = 1.1.1.1

        [Peer]
        PublicKey = peer_public_key_here
        Endpoint = server.example.com:51820
        AllowedIPs = 0.0.0.0/0
        """.data(using: .utf8)!

        do {
            try await fileDatabase.saveFile(data: wireguardConfig, path: "wireguard.conf")

            let retrievedConfig = try await fileDatabase.readFile(path: "wireguard.conf")
            XCTAssertEqual(retrievedConfig, wireguardConfig)

            // Verify content structure
            let configString = String(data: retrievedConfig, encoding: .utf8)
            XCTAssertNotNil(configString)
            XCTAssertTrue(configString!.contains("[Interface]"))
            XCTAssertTrue(configString!.contains("[Peer]"))
        } catch {
            XCTFail("Expected WireGuard config operations to succeed, but got error: \(error)")
        }
    }

    // MARK: Error Handling Tests

    func test_saveFile_errorCondition_shouldThrowWriteError() async {
        mockFileDatabase.shouldThrowOnSave = true
        mockFileDatabase.customSaveError = FileDatabaseError.writeError("Test save error")

        do {
            try await fileDatabase.saveFile(data: testData, path: testPath)
            XCTFail("Expected saveFile to throw error")
        } catch FileDatabaseError.writeError(let message) {
            XCTAssertEqual(message, "Test save error")
        } catch {
            XCTFail("Expected FileDatabaseError.writeError, but got: \(error)")
        }
    }

    func test_readFile_errorCondition_shouldThrowWriteError() async {
        mockFileDatabase.shouldThrowOnRead = true
        mockFileDatabase.customReadError = FileDatabaseError.writeError("Test read error")

        do {
            _ = try await fileDatabase.readFile(path: testPath)
            XCTFail("Expected readFile to throw error")
        } catch FileDatabaseError.writeError(let message) {
            XCTAssertEqual(message, "Test read error")
        } catch {
            XCTFail("Expected FileDatabaseError.writeError, but got: \(error)")
        }
    }

    func test_removeFile_errorCondition_shouldThrowDeleteError() async {
        mockFileDatabase.shouldThrowOnRemove = true
        mockFileDatabase.customRemoveError = FileDatabaseError.deleteError("Test remove error")

        do {
            try await fileDatabase.removeFile(path: testPath)
            XCTFail("Expected removeFile to throw error")
        } catch FileDatabaseError.deleteError(let message) {
            XCTAssertEqual(message, "Test remove error")
        } catch {
            XCTFail("Expected FileDatabaseError.deleteError, but got: \(error)")
        }
    }

    // MARK: Path Handling Tests

    func test_saveFile_specialCharactersInPath_shouldHandle() async {
        let specialPath = "file-with-special_chars@123.config"

        do {
            try await fileDatabase.saveFile(data: testData, path: specialPath)
            let retrievedData = try await fileDatabase.readFile(path: specialPath)
            XCTAssertEqual(retrievedData, testData)
        } catch {
            XCTFail("Expected special character path handling to succeed, but got error: \(error)")
        }
    }

    func test_saveFile_longPath_shouldHandle() async {
        let longPath = String(repeating: "very_long_path_", count: 10) + ".txt"

        do {
            try await fileDatabase.saveFile(data: testData, path: longPath)
            let retrievedData = try await fileDatabase.readFile(path: longPath)
            XCTAssertEqual(retrievedData, testData)
        } catch {
            XCTFail("Expected long path handling to succeed, but got error: \(error)")
        }
    }

    // MARK: Concurrency Tests

    func test_concurrentOperations_shouldHandleGracefully() async {
        let concurrentOperationCount = 10

        await withTaskGroup(of: Void.self) { group in
            // Start multiple concurrent save operations
            for i in 0..<concurrentOperationCount {
                group.addTask {
                    let path = "concurrent_file_\(i).txt"
                    let data = "Concurrent data \(i)".data(using: .utf8)!

                    do {
                        try await self.fileDatabase.saveFile(data: data, path: path)
                        let retrievedData = try await self.fileDatabase.readFile(path: path)
                        XCTAssertEqual(retrievedData, data)
                        try await self.fileDatabase.removeFile(path: path)
                    } catch {
                        XCTFail("Concurrent operation \(i) failed: \(error)")
                    }
                }
            }
        }

        // All operations should have completed and cleaned up
        XCTAssertEqual(mockFileDatabase.getFileCount(), 0)
    }

    // MARK: Edge Cases

    func test_saveFile_zeroByteFile_shouldHandle() async {
        let emptyData = Data()

        do {
            try await fileDatabase.saveFile(data: emptyData, path: "zero_byte.txt")
            let retrievedData = try await fileDatabase.readFile(path: "zero_byte.txt")
            XCTAssertEqual(retrievedData, emptyData)
            XCTAssertEqual(retrievedData.count, 0)
        } catch {
            XCTFail("Expected zero byte file handling to succeed, but got error: \(error)")
        }
    }

    func test_multipleOperationsOnSameFile_shouldHandle() async {
        let data1 = "Data 1".data(using: .utf8)!
        let data2 = "Data 2".data(using: .utf8)!
        let data3 = "Data 3".data(using: .utf8)!

        do {
            // Multiple saves to same path
            try await fileDatabase.saveFile(data: data1, path: testPath)
            try await fileDatabase.saveFile(data: data2, path: testPath)
            try await fileDatabase.saveFile(data: data3, path: testPath)

            // Should have latest data
            let finalData = try await fileDatabase.readFile(path: testPath)
            XCTAssertEqual(finalData, data3)
            XCTAssertEqual(mockFileDatabase.getFileCount(), 1)
        } catch {
            XCTFail("Expected multiple operations on same file to succeed, but got error: \(error)")
        }
    }

    // MARK: FilePaths Constants Tests

    func test_filePaths_openVPN_shouldWork() async {
        do {
            try await fileDatabase.saveFile(data: testData, path: FilePaths.openVPN)
            let retrievedData = try await fileDatabase.readFile(path: FilePaths.openVPN)
            XCTAssertEqual(retrievedData, testData)
        } catch {
            XCTFail("Expected FilePaths.openVPN operations to succeed, but got error: \(error)")
        }
    }

    func test_filePaths_wireGuard_shouldWork() async {
        do {
            try await fileDatabase.saveFile(data: testData, path: FilePaths.wireGuard)
            let retrievedData = try await fileDatabase.readFile(path: FilePaths.wireGuard)
            XCTAssertEqual(retrievedData, testData)
        } catch {
            XCTFail("Expected FilePaths.wireGuard operations to succeed, but got error: \(error)")
        }
    }
}
