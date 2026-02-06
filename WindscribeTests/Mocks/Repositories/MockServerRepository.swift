//
//  MockServerRepository.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-02-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockServerRepository: ServerRepository {

    // Protocol Properties

    var serverListSubject = CurrentValueSubject<[ServerModel], Never>([])
    var favouriteListSubject = CurrentValueSubject<[FavouriteModel], Never>([])
    var hasPinnedNodeMismatch = false

    var currentServerModels: [ServerModel] = []

    var currentGroupModels: [GroupModel] {
        return currentServerModels
            .flatMap { $0.groups }
    }

    // Mock Configuration

    var shouldThrowError = false
    var errorToThrow: Error = Errors.notDefined
    var mockServers: [ServerModel] = []
    var mockFavourites: [FavouriteModel] = []

    // Tracking

    var updatedServersCalled = false
    var updateRegionsCalled = false
    var lastSavedFavourite: FavouriteModel?
    var lastRemovedFavouriteId: String?

    // ServerRepository Implementation

    func updatedServers() async throws {
        updatedServersCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        currentServerModels = mockServers
        serverListSubject.send(currentServerModels)
    }

    func updateRegions(with regions: [ExportedRegion]) {
        updateRegionsCalled = true
    }

    func getFavorite(from locationId: String) -> FavouriteModel? {
        return mockFavourites.first { $0.id == locationId }
    }

    func getLocationPinned(for groupId: Int) -> String? {
        return mockFavourites.first { $0.id == "\(groupId)" }?.pinnedNodeIp
    }

    func removeFavorite(with groupId: String) {
        lastRemovedFavouriteId = groupId
        mockFavourites.removeAll { $0.id == groupId }
        favouriteListSubject.send(mockFavourites)
    }

    func removeFavorite(with groupId: Int) {
        removeFavorite(with: "\(groupId)")
    }

    func saveFavorite(for favourite: FavouriteModel) {
        lastSavedFavourite = favourite
        if let index = mockFavourites.firstIndex(where: { $0.id == favourite.id }) {
            mockFavourites[index] = favourite
        } else {
            mockFavourites.append(favourite)
        }
        favouriteListSubject.send(mockFavourites)
    }

    func saveLastConnectedHost(for hostName: String, with locationId: String) {
        // No-op for mock
    }

    // MARK: Helper Methods

    func reset() {
        updatedServersCalled = false
        updateRegionsCalled = false
        shouldThrowError = false
        errorToThrow = Errors.notDefined
        mockServers = []
        mockFavourites = []
        currentServerModels = []
        lastSavedFavourite = nil
        lastRemovedFavouriteId = nil
    }
}
