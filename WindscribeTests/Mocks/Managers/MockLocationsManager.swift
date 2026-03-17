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
    var mockLocationUIInfo: LocationUIInfo = LocationUIInfo(nickName: "", cityName: "", countryCode: "", isServer: false)

    var getLocationCalled = false
    var saveLastSelectedLocationCalled = false
    var lastSavedLocationID: String?
    var saveBestLocationCalled = false
    var lastSavedBestLocationID: String?
    var mockBestLocation: Int = 0

    var selectedLocationUpdated = CurrentValueSubject<Bool, Never>(false)
    let bestLocationUpdatedTrigger = PassthroughSubject<Void, Never>()

    // MARK: Protocol Methods

    func getLocation(from datacenterId: Int) throws -> (LocationModel, DatacenterModel) {
        getLocationCalled = true

        if let error = mockLocationError {
            throw error
        }

        guard let location = mockLocation else {
            throw VPNConfigurationErrors.locationNotFound(String(datacenterId))
        }

        return location
    }

    func getLocation(from datacenterId: String) throws -> (LocationModel, DatacenterModel) {
        getLocationCalled = true

        if let error = mockLocationError {
            throw error
        }

        guard let location = mockLocation else {
            throw VPNConfigurationErrors.locationNotFound(datacenterId)
        }

        return location
    }

    func saveLastSelectedLocation(with locationID: String) {
        saveLastSelectedLocationCalled = true
        lastSavedLocationID = locationID
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

    func saveStaticIP(withID staticID: Int?) {}

    func saveCustomConfig(withID staticID: String?) {}

    func clearLastSelectedLocation() {}

    func saveBestLocation(with locationID: String) {
        saveBestLocationCalled = true
        lastSavedBestLocationID = locationID
        mockBestLocation = Int(locationID) ?? 0
        bestLocationUpdatedTrigger.send(())
    }

    func selectBestLocation(with locationID: String) {}

    func getBestLocation() -> Int { return mockBestLocation }

    func getLastSelectedLocation() -> String { return "" }

    func getLocationType() -> LocationType? { return nil }

    func getLocationType(id: String) -> LocationType? { return nil }

    func getId() -> Int { return 0 }

    func getId(location: String) -> Int { return 0 }

    func getCustomId(location: String) -> String { return "" }

    func isCustomConfigSelected() -> Bool { return false }

    func checkLocationValidity() {}

    func checkForForceDisconnect() -> Bool { return false }

    // MARK: Helper Methods

    func reset() {
        mockLocation = nil
        mockLocationError = nil
        mockLocationUIInfo = LocationUIInfo(nickName: "", cityName: "", countryCode: "", isServer: false)
        getLocationCalled = false
        saveLastSelectedLocationCalled = false
        lastSavedLocationID = nil
        saveBestLocationCalled = false
        lastSavedBestLocationID = nil
        mockBestLocation = 0
    }
}
