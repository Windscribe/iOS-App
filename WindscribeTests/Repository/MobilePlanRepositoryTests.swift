//
//  MobilePlanRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-20.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class MobilePlanRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: MobilePlanRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockLogger: MockLogger!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockLogger = MockLogger()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        // Register MobilePlanRepository
        mockContainer.register(MobilePlanRepository.self) { r in
            return MobilePlanRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        // Resolve repository from container
        repository = mockContainer.resolve(MobilePlanRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockLogger = nil
        repository = nil
        super.tearDown()
    }

    // MARK: Success Tests

    func test_getMobilePlans_success_shouldReturnMobilePlans() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When
        let result = try await repository.getMobilePlans(promo: nil)

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result.first?.extId, "com.windscribe.ios.1year")
        XCTAssertEqual(result.first?.name, "Pro 1 Year")
        XCTAssertTrue(mockAPIManager.getMobileBillingPlansCalled)
    }

    func test_getMobilePlans_withPromo_shouldPassPromoCode() async throws {
        // Given
        let promoCode = "SUMMER2025"
        let jsonData = SampleDataMobilePlan.discountedMobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When
        _ = try await repository.getMobilePlans(promo: promoCode)

        // Then
        XCTAssertTrue(mockAPIManager.getMobileBillingPlansCalled)
        XCTAssertEqual(mockAPIManager.lastPromoCode, promoCode)
    }

    func test_getMobilePlans_success_shouldSaveToLocalDatabase() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList
        mockLocalDatabase.saveMobilePlansCalled = false

        // When
        _ = try await repository.getMobilePlans(promo: nil)

        // Then
        XCTAssertTrue(mockLocalDatabase.saveMobilePlansCalled, "Should save mobile plans to local database")
        XCTAssertNotNil(mockLocalDatabase.mobilePlansToReturn)
        XCTAssertEqual(mockLocalDatabase.mobilePlansToReturn?.count, 3)
    }

    func test_getMobilePlans_discountedPlan_shouldReturnCorrectly() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.discountedMobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When
        let result = try await repository.getMobilePlans(promo: "PROMO50")

        // Then
        XCTAssertEqual(result.count, 2)
        let discountedPlan = result.first(where: { $0.discount >= 0 })
        XCTAssertNotNil(discountedPlan)
        XCTAssertEqual(discountedPlan?.discount, 50)
        XCTAssertEqual(discountedPlan?.name, "Pro 1 Year (50% Off)")
    }

    func test_getMobilePlans_singlePlan_shouldReturnCorrectly() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.singleMobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When
        let result = try await repository.getMobilePlans(promo: nil)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.extId, "com.windscribe.ios.1year")
        XCTAssertEqual(result.first?.duration, 12)
    }

    // MARK: Fallback Tests

    func test_getMobilePlans_apiFailure_withCachedData_shouldReturnCachedData() async throws {
        // Given
        let cachedMobilePlans = createMockMobilePlans()
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.mobilePlansToReturn = cachedMobilePlans

        // When
        let result = try await repository.getMobilePlans(promo: nil)

        // Then
        XCTAssertEqual(result.count, cachedMobilePlans.count)
        XCTAssertEqual(result.first?.extId, cachedMobilePlans.first?.extId)
    }

    func test_getMobilePlans_apiFailure_noCachedData_shouldThrowError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.mobilePlansToReturn = nil

        // When/Then
        do {
            _ = try await repository.getMobilePlans(promo: nil)
            XCTFail("Should throw error when API fails and no cached data")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_getMobilePlans_apiFailure_emptyCachedData_shouldThrowError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.mobilePlansToReturn = []

        // When/Then
        do {
            _ = try await repository.getMobilePlans(promo: nil)
            XCTFail("Should throw error when API fails and cached data is empty")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: Integration Tests

    func test_getMobilePlans_multipleCalls_shouldWorkCorrectly() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When - call multiple times
        let result1 = try await repository.getMobilePlans(promo: nil)
        let result2 = try await repository.getMobilePlans(promo: nil)

        // Then
        XCTAssertEqual(result1.count, result2.count)
        XCTAssertEqual(result1.first?.extId, result2.first?.extId)
    }

    func test_getMobilePlans_apiSuccess_afterPreviousFailure_shouldReturnNewData() async throws {
        // Given - first call fails
        mockAPIManager.shouldThrowError = true
        mockLocalDatabase.mobilePlansToReturn = createMockMobilePlans()
        _ = try await repository.getMobilePlans(promo: nil)

        // When - second call succeeds
        mockAPIManager.shouldThrowError = false
        let jsonData = SampleDataMobilePlan.discountedMobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        let result = try await repository.getMobilePlans(promo: "PROMO50")

        // Then
        XCTAssertEqual(result.count, 2)
        let discountedPlan = result.first(where: { $0.discount >= 0 })
        XCTAssertNotNil(discountedPlan)
        XCTAssertEqual(discountedPlan?.discount, 50)
    }

    func test_getMobilePlans_withAndWithoutPromo_shouldWorkCorrectly() async throws {
        // Given
        let standardJsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
        let standardPlanList = try! JSONDecoder().decode(MobilePlanList.self, from: standardJsonData)

        let discountedJsonData = SampleDataMobilePlan.discountedMobilePlanListJSON.data(using: .utf8)!
        let discountedPlanList = try! JSONDecoder().decode(MobilePlanList.self, from: discountedJsonData)

        // When - call without promo
        mockAPIManager.mobilePlanListToReturn = standardPlanList
        let resultNoPromo = try await repository.getMobilePlans(promo: nil)

        // Then - verify no promo call
        XCTAssertNil(mockAPIManager.lastPromoCode)
        XCTAssertEqual(resultNoPromo.count, 3)
        XCTAssertTrue(resultNoPromo.allSatisfy { $0.discount == -1 })

        // When - call with promo
        mockAPIManager.mobilePlanListToReturn = discountedPlanList
        let resultWithPromo = try await repository.getMobilePlans(promo: "SUMMER50")

        // Then - verify promo call
        XCTAssertEqual(mockAPIManager.lastPromoCode, "SUMMER50")
        XCTAssertEqual(resultWithPromo.count, 2)
        XCTAssertTrue(resultWithPromo.contains(where: { $0.discount >= 0 }))
    }

    // MARK: Edge Cases

    func test_getMobilePlans_emptyMobilePlanList_shouldReturnEmptyArray() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.emptyMobilePlanListJSON.data(using: .utf8)!
        let emptyMobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = emptyMobilePlanList

        // When
        let result = try await repository.getMobilePlans(promo: nil)

        // Then
        XCTAssertEqual(result.count, 0)
    }

    func test_getMobilePlans_verifyMobilePlanProperties() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.singleMobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When
        let result = try await repository.getMobilePlans(promo: nil)

        // Then
        let mobilePlan = result.first!
        XCTAssertEqual(mobilePlan.extId, "com.windscribe.ios.1year")
        XCTAssertEqual(mobilePlan.name, "Pro 1 Year")
        XCTAssertEqual(mobilePlan.price, "$49.00")
        XCTAssertEqual(mobilePlan.type, "subscription")
        XCTAssertEqual(mobilePlan.duration, 12)
        XCTAssertEqual(mobilePlan.discount, -1)
        XCTAssertTrue(mobilePlan.active)
    }

    func test_getMobilePlans_withDifferentErrors_shouldHandleCorrectly() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.notDefined
        mockLocalDatabase.mobilePlansToReturn = nil

        // When/Then
        do {
            _ = try await repository.getMobilePlans(promo: nil)
            XCTFail("Should throw error")
        } catch let error as Errors {
            XCTAssertEqual(error, Errors.notDefined)
        } catch {
            XCTFail("Should throw Errors.notDefined")
        }
    }

    func test_getMobilePlans_nilPromo_shouldWorkCorrectly() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When
        let result = try await repository.getMobilePlans(promo: nil)

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertNil(mockAPIManager.lastPromoCode)
    }

    func test_getMobilePlans_emptyStringPromo_shouldPassCorrectly() async throws {
        // Given
        let jsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        mockAPIManager.mobilePlanListToReturn = mobilePlanList

        // When
        let result = try await repository.getMobilePlans(promo: "")

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(mockAPIManager.lastPromoCode, "")
    }

    // MARK: Helper Methods

    private func createMockMobilePlans() -> [MobilePlan] {
        let jsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
        let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
        return Array(mobilePlanList.mobilePlans)
    }
}
