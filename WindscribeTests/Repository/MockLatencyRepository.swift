//
//  MockLatencyRepository.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockLatencyRepository: LatencyRepository {


    // Protocol Properties
    var latency = CurrentValueSubject<[PingDataModel], Never>([])
    var latencyUpdatedTrigger = PassthroughSubject<Void, Never>()

    // Mock Configuration
    var shouldThrowErrorOnLoadLatency = false
    var shouldThrowErrorOnQuickLatency = false
    var errorToThrow: Error = Errors.notDefined

    var mockPingData: [PingDataModel] = []
    var mockBestLocationId: String?

    // Tracking
    var getPingDataCalled = false
    var lastQueriedIp: String?
    var loadLatencyCalled = false
    var loadQuickLatencyCalled = false
    var loadStaticIpLatencyCalled = false
    var loadCustomConfigLatencyCalled = false
    var pickBestLocationWithDataCalled = false
    var pickBestLocationCalled = false
    var refreshBestLocationCalled = false
    var checkLocationsValidityCalled = false

    // LatencyRepository Implementation

    func getPingData(ip: String) -> PingDataModel? {
        getPingDataCalled = true
        lastQueriedIp = ip
        return mockPingData.first { $0.ip == ip }
    }

    func loadLatency() async throws {
        loadLatencyCalled = true

        if shouldThrowErrorOnLoadLatency {
            throw errorToThrow
        }

        latency.send(mockPingData)
    }

    func loadQuickLatency() async throws {
        loadQuickLatencyCalled = true

        if shouldThrowErrorOnQuickLatency {
            throw errorToThrow
        }

        // Simulate quick latency with subset of data
        let quickData = Array(mockPingData.prefix(10))
        latency.send(quickData)
    }

    func loadStaticIpLatency() async {
        loadStaticIpLatencyCalled = true
    }

    func loadCustomConfigLatency() async {
        loadCustomConfigLatencyCalled = true
    }

    func pickBestLocation(pingData: [PingDataModel]) {
        pickBestLocationWithDataCalled = true
    }

    func pickBestLocation() {
        pickBestLocationCalled = true
    }

    func refreshBestLocation() {
        refreshBestLocationCalled = true
    }

    func checkLocationsValidity() async {
        checkLocationsValidityCalled = true
    }

    // MARK: Helper Methods

    func reset() {
        latency.send([])
        shouldThrowErrorOnLoadLatency = false
        shouldThrowErrorOnQuickLatency = false
        errorToThrow = Errors.notDefined
        mockPingData = []
        mockBestLocationId = nil
        getPingDataCalled = false
        lastQueriedIp = nil
        loadLatencyCalled = false
        loadQuickLatencyCalled = false
        loadStaticIpLatencyCalled = false
        loadCustomConfigLatencyCalled = false
        pickBestLocationWithDataCalled = false
        pickBestLocationCalled = false
        refreshBestLocationCalled = false
        checkLocationsValidityCalled = false
    }
}
