//
//  MockLocationsManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-01-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockLocationsManager: LocationsManager {

    // MARK: Protocol Properties
    var mockLocation: (LocationModel, DatacenterModel)?
    var mockLocationError: Error?
    var mockConnectionTargetType: ConnectionTargetType?
    var mockLocationUIInfo: LocationUIInfo = LocationUIInfo(nickName: "", cityName: "", countryCode: "", isServer: false)

    var getLocationCalled = false
    var saveLastConnectionTargetCalled = false
    var lastSavedLocationId: String?
    var saveBestLocationCalled = false
    var lastSavedBestLocationId: String?
    var mockBestLocation: Int = 0

    var selectedLocationUpdated = CurrentValueSubject<Bool, Never>(false)
    let bestLocationUpdatedTrigger = PassthroughSubject<Void, Never>()

    // MARK: Protocol Methods

    func getLocationDatacenter(from datacenterId: Int) throws -> (LocationModel, DatacenterModel) {
        getLocationCalled = true

        if let error = mockLocationError {
            throw error
        }

        guard let location = mockLocation else {
            throw VPNConfigurationErrors.locationNotFound(String(datacenterId))
        }

        return location
    }

    func getLocationDatacenter(from datacenterId: String) throws -> (LocationModel, DatacenterModel) {
        getLocationCalled = true

        if let error = mockLocationError {
            throw error
        }

        guard let location = mockLocation else {
            throw VPNConfigurationErrors.locationNotFound(datacenterId)
        }

        return location
    }

    func saveLastConnectionTarget(with locationId: String) {
        saveLastConnectionTargetCalled = true
        lastSavedLocationId = locationId
    }

    func getBestLocationModel(from datacenterId: Int) -> BestLocationModel? {
        // Return a best location model if we have mock data
        guard let (location, datacenter) = mockLocation else { return nil }
        return BestLocationModel(datacenter: datacenter, location: location)
    }

    func getBestLocationModel() -> BestLocationModel? {
        guard let (location, datacenter) = mockLocation else { return nil }
        return BestLocationModel(datacenter: datacenter, location: location)
    }

    func getLocationUIInfo() -> LocationUIInfo {
        return mockLocationUIInfo
    }

    func saveStaticIP(withId staticId: Int?) {}

    func saveCustomConfig(withId customId: String?) {}

    func clearLastConnectionTarget() {}

    func saveBestLocation(with locationId: String) {
        saveBestLocationCalled = true
        lastSavedBestLocationId = locationId
        mockBestLocation = Int(locationId) ?? 0
        bestLocationUpdatedTrigger.send(())
    }

    func selectBestLocation(with locationId: String) {}

    func getBestLocation() -> Int { return mockBestLocation }

    func getLastConnectionTarget() -> String { return "" }

    func getConnectionTargetType() -> ConnectionTargetType? { return mockConnectionTargetType }

    func getConnectionTargetType(id: String) -> ConnectionTargetType? { return mockConnectionTargetType }

    func getLastConnectionTargetId() -> Int { return 0 }

    func getLastConnectionTargetId(location: String) -> Int { return 0 }

    func getCustomId(location: String) -> String { return "" }

    func isCustomConfigSelected() -> Bool { return false }

    func checkLocationValidity() {}

    func checkForForceDisconnect() -> Bool { return false }

    func getIsProDatacenterSelected() -> Bool {
        return false
    }

    // MARK: Helper Methods

    func reset() {
        mockLocation = nil
        mockLocationError = nil
        mockConnectionTargetType = nil
        mockLocationUIInfo = LocationUIInfo(nickName: "", cityName: "", countryCode: "", isServer: false)
        getLocationCalled = false
        saveLastConnectionTargetCalled = false
        lastSavedLocationId = nil
        saveBestLocationCalled = false
        lastSavedBestLocationId = nil
        mockBestLocation = 0
    }
}
