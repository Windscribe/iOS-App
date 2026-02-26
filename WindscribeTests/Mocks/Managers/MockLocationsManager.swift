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
    var mockLocation: (ServerModel, GroupModel)?
    var mockLocationError: Error?
    var mockLocationUIInfo: LocationUIInfo = LocationUIInfo(nickName: "", cityName: "", countryCode: "", isServer: false)

    var getLocationCalled = false
    var saveLastSelectedLocationCalled = false
    var lastSavedLocationID: String?
    var saveBestLocationCalled = false
    var lastSavedBestLocationID: String?
    var mockBestLocation: String = "0"

    var selectedLocationUpdated = CurrentValueSubject<Bool, Never>(false)
    var bestLocationUpdated = CurrentValueSubject<String, Never>("")

    // MARK: Protocol Methods

    func getLocation(from groupId: String) throws -> (ServerModel, GroupModel) {
        getLocationCalled = true

        if let error = mockLocationError {
            throw error
        }

        guard let location = mockLocation else {
            throw VPNConfigurationErrors.locationNotFound(groupId)
        }

        return location
    }

    func saveLastSelectedLocation(with locationID: String) {
        saveLastSelectedLocationCalled = true
        lastSavedLocationID = locationID
    }

    func getBestLocationModel(from groupId: String) -> BestLocationModel? { return nil }
    func getBestLocationModel() -> BestLocationModel? { return nil }
    func getLocationUIInfo() -> LocationUIInfo {
        return mockLocationUIInfo
    }
    func saveStaticIP(withID staticID: Int?) {}
    func saveCustomConfig(withID staticID: String?) {}
    func clearLastSelectedLocation() {}
    func saveBestLocation(with locationID: String) {
        saveBestLocationCalled = true
        lastSavedBestLocationID = locationID
        mockBestLocation = locationID
        bestLocationUpdated.send(locationID)
    }
    func selectBestLocation(with locationID: String) {}
    func getBestLocation() -> String { return mockBestLocation }
    func getLastSelectedLocation() -> String { return "" }
    func getLocationType() -> LocationType? { return nil }
    func getLocationType(id: String) -> LocationType? { return nil }
    func getId() -> String { return "" }
    func getId(location: String) -> String { return "" }
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
        mockBestLocation = "0"
    }
}
