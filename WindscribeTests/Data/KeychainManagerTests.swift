//
//  KeychainManagerTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-09-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class KeychainManagerTests: XCTestCase {

    var mockContainer: Container!

    // Test constants
    private let testService = "TestService"
    private let testKey = "TestKey"
    private let testString = "TestStringValue"
    private var testAccessGroup: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return SharedKeys.sharedKeychainGroup
        #endif
    }

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockContainer.register(KeychainManager.self) { _ in
            return KeychainManagerImpl(logger: MockLogger())
        }.inObjectScope(.container)
    }

    override func tearDown() {
        mockContainer = nil
        super.tearDown()
    }

    // MARK: - String Storage Tests

    func test_setString_shouldStoreAndRetrieveString() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        XCTAssertNoThrow(try keychainManager.setString(testString, forKey: testKey, service: testService, accessGroup: nil))

        let retrievedString = try? keychainManager.getString(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrievedString, testString)
    }

    func test_setString_withAccessGroup_shouldStoreAndRetrieveString() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        XCTAssertNoThrow(try keychainManager.setString(testString, forKey: testKey, service: testService, accessGroup: testAccessGroup))

        let retrievedString = try? keychainManager.getString(forKey: testKey, service: testService, accessGroup: testAccessGroup)
        XCTAssertEqual(retrievedString, testString)
    }

    func test_getString_nonExistentKey_shouldThrowError() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        XCTAssertThrowsError(try keychainManager.getString(forKey: "NonExistentKey", service: testService, accessGroup: nil)) { error in
            XCTAssertTrue(error is KeychainError)
            if let keychainError = error as? KeychainError,
               case .itemNotFound = keychainError {
                // Expected error
            } else {
                XCTFail("Expected KeychainError.itemNotFound")
            }
        }
    }

    // MARK: - Data Storage Tests

    func test_setData_shouldStoreAndRetrieveData() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let testData = "TestData".data(using: .utf8)!

        XCTAssertNoThrow(try keychainManager.setData(testData, forKey: testKey, service: testService, accessGroup: nil))

        let retrievedData = try? keychainManager.getData(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrievedData, testData)
    }

    func test_setData_withAccessGroup_shouldStoreAndRetrieveData() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let testData = "TestDataWithAccessGroup".data(using: .utf8)!

        XCTAssertNoThrow(try keychainManager.setData(testData, forKey: testKey, service: testService, accessGroup: testAccessGroup))

        let retrievedData = try? keychainManager.getData(forKey: testKey, service: testService, accessGroup: testAccessGroup)
        XCTAssertEqual(retrievedData, testData)
    }

    func test_getData_nonExistentKey_shouldThrowError() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        XCTAssertThrowsError(try keychainManager.getData(forKey: "NonExistentKey", service: testService, accessGroup: nil)) { error in
            XCTAssertTrue(error is KeychainError)
            if let keychainError = error as? KeychainError,
               case .itemNotFound = keychainError {
                // Expected error
            } else {
                XCTFail("Expected KeychainError.itemNotFound")
            }
        }
    }

    // MARK: - Update Tests

    func test_setString_existingKey_shouldUpdateValue() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let initialValue = "InitialValue"
        let updatedValue = "UpdatedValue"

        // Set initial value
        XCTAssertNoThrow(try keychainManager.setString(initialValue, forKey: testKey, service: testService, accessGroup: nil))

        // Verify initial value
        let retrievedInitial = try? keychainManager.getString(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrievedInitial, initialValue)

        // Update value
        XCTAssertNoThrow(try keychainManager.setString(updatedValue, forKey: testKey, service: testService, accessGroup: nil))

        // Verify updated value
        let retrievedUpdated = try? keychainManager.getString(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrievedUpdated, updatedValue)
    }

    // MARK: - Delete Tests

    func test_deleteItem_existingKey_shouldRemoveItem() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Store item first
        XCTAssertNoThrow(try keychainManager.setString(testString, forKey: testKey, service: testService, accessGroup: nil))

        // Verify item exists
        XCTAssertTrue(keychainManager.exists(key: testKey, service: testService, accessGroup: nil))

        // Delete item
        XCTAssertNoThrow(try keychainManager.deleteItem(forKey: testKey, service: testService, accessGroup: nil))

        // Verify item no longer exists
        XCTAssertFalse(keychainManager.exists(key: testKey, service: testService, accessGroup: nil))
    }

    func test_deleteItem_nonExistentKey_shouldNotThrow() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Deleting non-existent key should not throw error in mock
        XCTAssertNoThrow(try keychainManager.deleteItem(forKey: "NonExistentKey", service: testService, accessGroup: nil))
    }

    // MARK: - Exists Tests

    func test_exists_existingKey_shouldReturnTrue() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Store item first
        XCTAssertNoThrow(try keychainManager.setString(testString, forKey: testKey, service: testService, accessGroup: nil))

        // Check if item exists
        XCTAssertTrue(keychainManager.exists(key: testKey, service: testService, accessGroup: nil))
    }

    func test_exists_nonExistentKey_shouldReturnFalse() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Check if non-existent item exists
        XCTAssertFalse(keychainManager.exists(key: "NonExistentKey", service: testService, accessGroup: nil))
    }

    // MARK: - Service Isolation Tests

    func test_differentServices_shouldIsolateData() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let service1 = "Service1"
        let service2 = "Service2"
        let value1 = "Value1"
        let value2 = "Value2"

        // Store same key in different services
        XCTAssertNoThrow(try keychainManager.setString(value1, forKey: testKey, service: service1, accessGroup: nil))
        XCTAssertNoThrow(try keychainManager.setString(value2, forKey: testKey, service: service2, accessGroup: nil))

        // Verify values are isolated by service
        let retrieved1 = try? keychainManager.getString(forKey: testKey, service: service1, accessGroup: nil)
        let retrieved2 = try? keychainManager.getString(forKey: testKey, service: service2, accessGroup: nil)

        XCTAssertEqual(retrieved1, value1)
        XCTAssertEqual(retrieved2, value2)
        XCTAssertNotEqual(retrieved1, retrieved2)
    }

    // MARK: - Access Group Tests

    // MARK: - Error Handling Tests

    func test_getString_afterDelete_shouldThrowItemNotFound() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Store and then delete item
        XCTAssertNoThrow(try keychainManager.setString(testString, forKey: testKey, service: testService, accessGroup: nil))
        XCTAssertNoThrow(try keychainManager.deleteItem(forKey: testKey, service: testService, accessGroup: nil))

        // Attempt to retrieve deleted item
        XCTAssertThrowsError(try keychainManager.getString(forKey: testKey, service: testService, accessGroup: nil)) { error in
            XCTAssertTrue(error is KeychainError)
            if let keychainError = error as? KeychainError,
               case .itemNotFound = keychainError {
                // Expected error
            } else {
                XCTFail("Expected KeychainError.itemNotFound")
            }
        }
    }

    func test_errorHandling_shouldHandleInvalidData() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Test retrieving non-existent item returns proper error
        XCTAssertThrowsError(try keychainManager.getString(forKey: "NonExistentKey", service: "NonExistentService", accessGroup: nil)) { error in
            XCTAssertTrue(error is KeychainError)
            if let keychainError = error as? KeychainError,
               case .itemNotFound = keychainError {
                // Expected error
            } else {
                XCTFail("Expected KeychainError.itemNotFound")
            }
        }

        // Test that deleting non-existent item doesn't throw (should be handled gracefully)
        XCTAssertNoThrow(try keychainManager.deleteItem(forKey: "NonExistentKey", service: "NonExistentService", accessGroup: nil))

        // Test exists returns false for non-existent items
        XCTAssertFalse(keychainManager.exists(key: "NonExistentKey", service: "NonExistentService", accessGroup: nil))
    }

    // MARK: - Edge Cases

    func test_setString_emptyString_shouldStoreAndRetrieve() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let emptyString = ""

        XCTAssertNoThrow(try keychainManager.setString(emptyString, forKey: testKey, service: testService, accessGroup: nil))

        let retrieved = try? keychainManager.getString(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrieved, emptyString)
    }

    func test_setData_emptyData_shouldStoreAndRetrieve() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let emptyData = Data()

        XCTAssertNoThrow(try keychainManager.setData(emptyData, forKey: testKey, service: testService, accessGroup: nil))

        let retrieved = try? keychainManager.getData(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrieved, emptyData)
    }

    func test_setString_specialCharacters_shouldStoreAndRetrieve() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let specialString = "!@#$%^&*()_+-={}[]|\\:;\"'<>?,./"

        XCTAssertNoThrow(try keychainManager.setString(specialString, forKey: testKey, service: testService, accessGroup: nil))

        let retrieved = try? keychainManager.getString(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrieved, specialString)
    }

    func test_setString_longString_shouldStoreAndRetrieve() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let longString = String(repeating: "Testing Keychain Storage with Long String Content ", count: 100)

        XCTAssertNoThrow(try keychainManager.setString(longString, forKey: testKey, service: testService, accessGroup: nil))

        let retrieved = try? keychainManager.getString(forKey: testKey, service: testService, accessGroup: nil)
        XCTAssertEqual(retrieved, longString)
    }

    // MARK: - Bundle ID Service Tests

    func test_setBundleData_shouldStoreAndRetrieveData() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let testData = "BundleTestData".data(using: .utf8)!
        let testKey = "BundleTestKey"

        XCTAssertNoThrow(try keychainManager.setBundleData(testData, forKey: testKey))

        let retrievedData = try? keychainManager.getBundleData(forKey: testKey)
        XCTAssertEqual(retrievedData, testData)
    }

    func test_getBundleData_nonExistentKey_shouldReturnNil() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        let retrievedData = try? keychainManager.getBundleData(forKey: "NonExistentBundleKey")
        XCTAssertNil(retrievedData)
    }

    func test_deleteBundleItem_existingKey_shouldRemoveItem() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let testData = "BundleDataToDelete".data(using: .utf8)!
        let testKey = "BundleKeyToDelete"

        XCTAssertNoThrow(try keychainManager.setBundleData(testData, forKey: testKey))
        XCTAssertTrue(keychainManager.bundleExists(key: testKey))

        XCTAssertNoThrow(try keychainManager.deleteBundleItem(forKey: testKey))
        XCTAssertFalse(keychainManager.bundleExists(key: testKey))
    }

    func test_bundleExists_existingKey_shouldReturnTrue() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let testData = "BundleExistsData".data(using: .utf8)!
        let testKey = "BundleExistsKey"

        XCTAssertNoThrow(try keychainManager.setBundleData(testData, forKey: testKey))
        XCTAssertTrue(keychainManager.bundleExists(key: testKey))
    }

    func test_bundleExists_nonExistentKey_shouldReturnFalse() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        XCTAssertFalse(keychainManager.bundleExists(key: "NonExistentBundleKey"))
    }

    func test_setBundleData_updateExistingKey_shouldUpdateValue() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        let initialData = "InitialBundleData".data(using: .utf8)!
        let updatedData = "UpdatedBundleData".data(using: .utf8)!
        let testKey = "BundleUpdateKey"

        XCTAssertNoThrow(try keychainManager.setBundleData(initialData, forKey: testKey))
        let retrievedInitial = try? keychainManager.getBundleData(forKey: testKey)
        XCTAssertEqual(retrievedInitial, initialData)

        XCTAssertNoThrow(try keychainManager.setBundleData(updatedData, forKey: testKey))
        let retrievedUpdated = try? keychainManager.getBundleData(forKey: testKey)
        XCTAssertEqual(retrievedUpdated, updatedData)
    }

    // MARK: - Mock-Specific Tests

    func test_keychainStorage_shouldMaintainDataIntegrity() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        let key1 = "IntegrityKey1"
        let key2 = "IntegrityKey2"
        let value1 = "IntegrityValue1"
        let value2 = "IntegrityValue2"

        // Clean up first
        try? keychainManager.deleteItem(forKey: key1, service: testService, accessGroup: nil)
        try? keychainManager.deleteItem(forKey: key2, service: testService, accessGroup: nil)

        // Initially both items should not exist
        XCTAssertFalse(keychainManager.exists(key: key1, service: testService, accessGroup: nil))
        XCTAssertFalse(keychainManager.exists(key: key2, service: testService, accessGroup: nil))

        // Add first item
        XCTAssertNoThrow(try keychainManager.setString(value1, forKey: key1, service: testService, accessGroup: nil))
        XCTAssertTrue(keychainManager.exists(key: key1, service: testService, accessGroup: nil))
        XCTAssertFalse(keychainManager.exists(key: key2, service: testService, accessGroup: nil))

        // Add second item
        XCTAssertNoThrow(try keychainManager.setString(value2, forKey: key2, service: testService, accessGroup: nil))
        XCTAssertTrue(keychainManager.exists(key: key1, service: testService, accessGroup: nil))
        XCTAssertTrue(keychainManager.exists(key: key2, service: testService, accessGroup: nil))

        // Delete first item, second should remain
        XCTAssertNoThrow(try keychainManager.deleteItem(forKey: key1, service: testService, accessGroup: nil))
        XCTAssertFalse(keychainManager.exists(key: key1, service: testService, accessGroup: nil))
        XCTAssertTrue(keychainManager.exists(key: key2, service: testService, accessGroup: nil))

        // Verify second item value is intact
        let retrievedValue2 = try? keychainManager.getString(forKey: key2, service: testService, accessGroup: nil)
        XCTAssertEqual(retrievedValue2, value2)

        // Clean up
        try? keychainManager.deleteItem(forKey: key2, service: testService, accessGroup: nil)
    }
}
