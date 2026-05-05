//
//  RobertyFiltersRepositoryTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 20/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import XCTest
import RealmSwift
@testable import Windscribe

class RobertyFiltersRepositoryTests: XCTestCase {
    var mockLogger: MockLogger!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var repository: RobertyFiltersRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockLogger = MockLogger()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        cancellables = Set<AnyCancellable>()

        repository = RobertyFiltersRepositoryImpl(
            logger: mockLogger,
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase
        )
    }

    override func tearDown() {
        cancellables = nil
        repository = nil
        mockLogger = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitializationLoadsFiltersFromDatabase() {
        // Given
        let mockLocalFilters: [RobertFilterModel] = [
            RobertFilterModel(id: "1", title: "Ads", filterDescription: "Description for Ads", status: 1, enabled: true),
            RobertFilterModel(id: "2", title: "Trackers", filterDescription: "Description for Trackers", status: 0, enabled: false)
        ]

        mockLocalDatabase.mockRobertFilters = mockLocalFilters

        // When - Create a new repository instance to test initialization
        let newRepository = RobertyFiltersRepositoryImpl(
            logger: mockLogger,
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase
        )

        // Then
        XCTAssertEqual(newRepository.robertFilters.value.count, 2, "Should load 2 filters from database")
        XCTAssertEqual(newRepository.robertFilters.value[0].id, "1")
        XCTAssertEqual(newRepository.robertFilters.value[0].title, "Ads")
        XCTAssertTrue(newRepository.robertFilters.value[0].enabled)
        XCTAssertEqual(newRepository.robertFilters.value[1].id, "2")
        XCTAssertEqual(newRepository.robertFilters.value[1].title, "Trackers")
        XCTAssertFalse(newRepository.robertFilters.value[1].enabled)
    }

    func testInitializationWithNoDatabaseFilters() {
        // Given
        mockLocalDatabase.mockRobertFilters = nil

        // When
        let newRepository = RobertyFiltersRepositoryImpl(
            logger: mockLogger,
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase
        )

        // Then
        XCTAssertTrue(newRepository.robertFilters.value.isEmpty, "Should have empty filters when database returns nil")
    }

    // MARK: - Refresh Filters Tests

    func testRefreshFiltersSuccessUpdatesFilters() async throws {
        // Given
        let filter1 = createMockRobertFilter(id: "1", title: "Ads", enabled: true)
        let filter2 = createMockRobertFilter(id: "2", title: "Malware", enabled: false)
        let robertFilters = RobertFilters()
        robertFilters.filters.append(filter1)
        robertFilters.filters.append(filter2)

        mockAPIManager.mockRobertFilters = robertFilters

        // When
        try await repository.refreshFilters()

        // Then
        XCTAssertTrue(mockAPIManager.getRobertFiltersCalled, "Should call API to get filters")
        XCTAssertTrue(mockLocalDatabase.saveRobertFiltersCalled, "Should save filters to database")
        XCTAssertEqual(mockLocalDatabase.lastSavedRobertFilters?.count, 2)
        XCTAssertEqual(repository.robertFilters.value.count, 2, "Should update subject with new filters")
        XCTAssertEqual(repository.robertFilters.value[0].title, "Ads")
        XCTAssertEqual(repository.robertFilters.value[1].title, "Malware")
    }

    func testRefreshFiltersFailureWithExistingFilters() async throws {
        // Given - Repository already has filters
        let existingLocalFilters: [RobertFilterModel] = [
            RobertFilterModel(id: "1", title: "Existing", filterDescription: "Description for Existing", status: 1, enabled: true)
        ]
        mockLocalDatabase.mockRobertFilters = existingLocalFilters

        // Create new repository to load existing filters
        repository = RobertyFiltersRepositoryImpl(
            logger: mockLogger,
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase
        )

        XCTAssertEqual(repository.robertFilters.value.count, 1, "Should have existing filter")

        // When - API fails
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noResponse

        // Then - Should not throw, should keep existing filters
        try await repository.refreshFilters()

        XCTAssertTrue(mockAPIManager.getRobertFiltersCalled, "Should attempt to call API")
        XCTAssertEqual(repository.robertFilters.value.count, 1, "Should keep existing filters")
        XCTAssertEqual(repository.robertFilters.value[0].title, "Existing")
    }

    func testRefreshFiltersFailureWithNoExistingFiltersLoadsFromDatabase() async throws {
        // Given - No existing filters in repository
        XCTAssertTrue(repository.robertFilters.value.isEmpty, "Should start with empty filters")

        // Set up database to have filters
        let dbLocalFilters: [RobertFilterModel] = [
            RobertFilterModel(id: "1", title: "Database Filter", filterDescription: "Description for Database Filter", status: 1, enabled: true)
        ]
        mockLocalDatabase.mockRobertFilters = dbLocalFilters

        // When - API fails
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noResponse

        try await repository.refreshFilters()

        // Then - Should load from database
        XCTAssertTrue(mockAPIManager.getRobertFiltersCalled, "Should attempt to call API")
        XCTAssertEqual(repository.robertFilters.value.count, 1, "Should load filters from database")
        XCTAssertEqual(repository.robertFilters.value[0].title, "Database Filter")
    }

    func testRefreshFiltersHandlesInvalidatedFilters() async throws {
        // Given
        let validFilter = createMockRobertFilter(id: "1", title: "Valid", enabled: true)
        let invalidFilter = createMockRobertFilter(id: "2", title: "Invalid", enabled: false)

        let robertFilters = RobertFilters()
        robertFilters.filters.append(validFilter)
        robertFilters.filters.append(invalidFilter)

        mockAPIManager.mockRobertFilters = robertFilters

        // When
        try await repository.refreshFilters()

        // Then
        XCTAssertEqual(repository.robertFilters.value.count, 2, "Should include all filters")
    }

    // MARK: - Update Filter Tests

    func testUpdateFilterEnableToDisableSuccess() async throws {
        // Given
        let filter = RobertFilterModel(id: "1",
                                       title: "Ads",
                                       filterDescription: "Block ads",
                                       status: 1,
                                       enabled: true)

        let mockMessage = createMockAPIMessage(success: true)
        mockAPIManager.mockAPIMessage = mockMessage

        let postUpdateLocalFilters1: [RobertFilterModel] = [
            RobertFilterModel(id: "1", title: "Ads", filterDescription: "Description for Ads", status: 0, enabled: false)
        ]
        mockLocalDatabase.mockRobertFilters = postUpdateLocalFilters1

        // When
        try await repository.updateFilter(filter)

        // Then
        XCTAssertTrue(mockAPIManager.updateRobertSettingsCalled, "Should call API to update settings")
        XCTAssertEqual(mockAPIManager.lastRobertFilterId, "1")
        XCTAssertEqual(mockAPIManager.lastRobertFilterStatus, 0, "Should set status to 0 (disable)")
        XCTAssertTrue(mockAPIManager.syncRobertFiltersCalled, "Should sync filters after update")
        XCTAssertTrue(mockLocalDatabase.toggleRobertRuleCalled, "Should toggle filter in database")
        XCTAssertEqual(mockLocalDatabase.lastToggledRobertRuleId, "1")
    }

    func testUpdateFilterDisableToEnableSuccess() async throws {
        // Given
        let filter = RobertFilterModel(
            id: "2",
            title: "Trackers",
            filterDescription: "Block trackers",
            status: 0,
            enabled: false
        )

        let mockMessage = createMockAPIMessage(success: true)
        mockAPIManager.mockAPIMessage = mockMessage

        let postUpdateLocalFilters2: [RobertFilterModel] = [
            RobertFilterModel(id: "2", title: "Trackers", filterDescription: "Description for Trackers", status: 1, enabled: true)
        ]
        mockLocalDatabase.mockRobertFilters = postUpdateLocalFilters2

        // When
        try await repository.updateFilter(filter)

        // Then
        XCTAssertTrue(mockAPIManager.updateRobertSettingsCalled, "Should call API to update settings")
        XCTAssertEqual(mockAPIManager.lastRobertFilterId, "2")
        XCTAssertEqual(mockAPIManager.lastRobertFilterStatus, 1, "Should set status to 1 (enable)")
        XCTAssertTrue(mockAPIManager.syncRobertFiltersCalled, "Should sync filters after update")
        XCTAssertTrue(mockLocalDatabase.toggleRobertRuleCalled, "Should toggle filter in database")
    }

    func testUpdateFilterSyncFailureThrowsError() async throws {
        // Given
        let filter = RobertFilterModel(
            id: "1",
            title: "Ads",
            filterDescription: "Block ads",
            status: 1,
            enabled: true
        )

        let mockMessage = createMockAPIMessage(success: true)
        mockAPIManager.mockAPIMessage = mockMessage
        mockAPIManager.shouldThrowSyncError = true
        let apiError = APIError(data: [
            APIParameters.Errors.errorCode: 500,
            APIParameters.Errors.errorDescription: "Sync failed",
            APIParameters.Errors.errorMessage: "Sync failed"
        ])
        mockAPIManager.customSyncError = Errors.apiError(apiError)

        // When/Then
        var didThrowError = false
        do {
            try await repository.updateFilter(filter)
        } catch let error as RobertFilterErrors {
            didThrowError = true
            switch error {
            case .failedSync(let message):
                // The message should either contain "Sync failed" or "Failed to sync Robert Settings."
                let containsExpectedMessage = message.contains("Sync failed") ||
                                             message.contains("Failed to sync Robert Settings.")
                XCTAssertTrue(containsExpectedMessage, "Error message was: '\(message)'")
                XCTAssertTrue(mockAPIManager.updateRobertSettingsCalled, "Should call update API")
                XCTAssertTrue(mockAPIManager.syncRobertFiltersCalled, "Should attempt sync")
                XCTAssertFalse(mockLocalDatabase.toggleRobertRuleCalled, "Should not toggle in database on sync failure")
            default:
                XCTFail("Should throw failedSync error")
            }
        } catch {
            didThrowError = true
            XCTFail("Should throw RobertFilterErrors, but got: \(type(of: error)) - \(error)")
        }

        // Verify that an error was actually thrown
        XCTAssertTrue(didThrowError, "Should have thrown an error but none was thrown")
    }

    func testUpdateFilterUpdateAPIFailureThrowsError() async throws {
        // Given
        let filter = RobertFilterModel(
            id: "1",
            title: "Ads",
            filterDescription: "Block ads",
            status: 1,
            enabled: true
        )

        mockAPIManager.shouldThrowError = true
        let apiError = APIError(data: [
            APIParameters.Errors.errorCode: 400,
            APIParameters.Errors.errorDescription: "Update failed",
            APIParameters.Errors.errorMessage: "Update failed"
        ])
        mockAPIManager.customError = Errors.apiError(apiError)

        // When/Then
        do {
            try await repository.updateFilter(filter)
            XCTFail("Should throw error when update fails")
        } catch let error as RobertFilterErrors {
            switch error {
            case .failedSync(let message):
                // The message should contain either "Update failed" or the default error text
                let containsExpectedMessage = message.contains("Update failed") ||
                                             message.contains("Failed to get filters")
                XCTAssertTrue(containsExpectedMessage, "Error message was: '\(message)'")
                XCTAssertTrue(mockAPIManager.updateRobertSettingsCalled, "Should call update API")
                XCTAssertFalse(mockAPIManager.syncRobertFiltersCalled, "Should not sync after update failure")
                XCTAssertFalse(mockLocalDatabase.toggleRobertRuleCalled, "Should not toggle in database on failure")
            default:
                XCTFail("Should throw failedSync error")
            }
        } catch {
            XCTFail("Should throw RobertFilterErrors, but got: \(error)")
        }
    }

    func testUpdateFilterNonAPIErrorThrowsWithDescription() async throws {
        // Given
        let filter = RobertFilterModel(
            id: "1",
            title: "Ads",
            filterDescription: "Block ads",
            status: 1,
            enabled: true
        )

        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noResponse

        // When/Then
        do {
            try await repository.updateFilter(filter)
            XCTFail("Should throw error")
        } catch let error as RobertFilterErrors {
            switch error {
            case .failedSync(let message):
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
                XCTAssertTrue(mockAPIManager.updateRobertSettingsCalled, "Should call update API")
            default:
                XCTFail("Should throw failedSync error")
            }
        } catch {
            XCTFail("Should throw RobertFilterErrors")
        }
    }

    // MARK: - Integration Tests

    func testCompleteWorkflowRefreshAndUpdate() async throws {
        // Given - Start with some filters
        let filter1 = createMockRobertFilter(id: "1", title: "Ads", enabled: true)
        let filter2 = createMockRobertFilter(id: "2", title: "Trackers", enabled: false)
        let robertFilters = RobertFilters()
        robertFilters.filters.append(filter1)
        robertFilters.filters.append(filter2)

        mockAPIManager.mockRobertFilters = robertFilters

        // When - Refresh filters
        try await repository.refreshFilters()

        // Then - Filters should be loaded
        XCTAssertEqual(repository.robertFilters.value.count, 2)
        let adsFilter = repository.robertFilters.value.first { $0.id == "1" }
        XCTAssertNotNil(adsFilter)
        XCTAssertTrue(adsFilter!.enabled)

        // When - Update a filter
        mockAPIManager.mockAPIMessage = createMockAPIMessage(success: true)
        let postUpdateIntegrationFilters: [RobertFilterModel] = [
            RobertFilterModel(id: "1", title: "Ads", filterDescription: "Description for Ads", status: 0, enabled: false),
            RobertFilterModel(id: "2", title: "Trackers", filterDescription: "Description for Trackers", status: 0, enabled: false)
        ]
        mockLocalDatabase.mockRobertFilters = postUpdateIntegrationFilters

        try await repository.updateFilter(adsFilter!)

        // Then - Should update successfully
        XCTAssertTrue(mockAPIManager.updateRobertSettingsCalled)
        XCTAssertTrue(mockAPIManager.syncRobertFiltersCalled)
        XCTAssertTrue(mockLocalDatabase.toggleRobertRuleCalled)
    }

    func testRobertFiltersPublisherEmitsChanges() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Filters should update")
        var receivedFilters: [[RobertFilterModel]] = []

        repository.robertFilters
            .sink { filters in
                receivedFilters.append(filters)
                if filters.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        let filter1 = createMockRobertFilter(id: "1", title: "Ads", enabled: true)
        let filter2 = createMockRobertFilter(id: "2", title: "Trackers", enabled: false)
        let robertFilters = RobertFilters()
        robertFilters.filters.append(filter1)
        robertFilters.filters.append(filter2)

        mockAPIManager.mockRobertFilters = robertFilters
        try await repository.refreshFilters()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedFilters.count >= 2, "Should receive at least 2 updates")
        XCTAssertEqual(receivedFilters.last?.count, 2)
    }

    // MARK: - Helper Methods

    private func createMockRobertFilter(id: String, title: String, enabled: Bool) -> RobertFilter {
        let filter = RobertFilter()
        filter.id = id
        filter.title = title
        filter.filterDescription = "Description for \(title)"
        filter.status = enabled ? 1 : 0
        filter.enabled = enabled
        return filter
    }

    private func createMockAPIMessage(success: Bool) -> APIMessage {
        APIMessage(message: "message", success: success)
    }
}
