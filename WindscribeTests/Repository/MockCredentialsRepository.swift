//
//  MockCredentialsRepository.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockCredentialsRepository: CredentialsRepository {

    // Protocol Properties
    var openVPNCrendentials: ServerCredentialsModel?
    var ikev2Crendentials: ServerCredentialsModel?

    // Mock Configuration
    var shouldThrowErrorOnOpenVPN = false
    var shouldThrowErrorOnIKEv2 = false
    var shouldThrowErrorOnServerConfig = false
    var errorToThrow: Error = Errors.notDefined

    var mockOpenVPNCredentials: ServerCredentialsModel?
    var mockIKEv2Credentials: ServerCredentialsModel?
    var mockServerCredentialsType: ServerCredentials.Type = OpenVPNServerCredentials.self

    // Tracking
    var getUpdatedOpenVPNCrendentialsCalled = false
    var getUpdatedIKEv2CrendentialsCalled = false
    var getUpdatedServerConfigCalled = false
    var selectedServerCredentialsTypeCalled = false
    var updateServerConfigCalled = false

    // CredentialsRepository Implementation

    func getUpdatedOpenVPNCrendentials() async throws {
        getUpdatedOpenVPNCrendentialsCalled = true

        if shouldThrowErrorOnOpenVPN {
            throw errorToThrow
        }

        openVPNCrendentials = mockOpenVPNCredentials
    }

    func getUpdatedIKEv2Crendentials() async throws {
        getUpdatedIKEv2CrendentialsCalled = true

        if shouldThrowErrorOnIKEv2 {
            throw errorToThrow
        }

        ikev2Crendentials = mockIKEv2Credentials
    }

    func getUpdatedServerConfig() async throws {
        getUpdatedServerConfigCalled = true

        if shouldThrowErrorOnServerConfig {
            throw errorToThrow
        }
    }

    func selectedServerCredentialsType() -> ServerCredentials.Type {
        selectedServerCredentialsTypeCalled = true
        return mockServerCredentialsType
    }

    func updateServerConfig() {
        updateServerConfigCalled = true
    }

    // MARK: Helper Methods

    func reset() {
        openVPNCrendentials = nil
        ikev2Crendentials = nil
        shouldThrowErrorOnOpenVPN = false
        shouldThrowErrorOnIKEv2 = false
        shouldThrowErrorOnServerConfig = false
        errorToThrow = Errors.notDefined
        mockOpenVPNCredentials = nil
        mockIKEv2Credentials = nil
        mockServerCredentialsType = OpenVPNServerCredentials.self
        getUpdatedOpenVPNCrendentialsCalled = false
        getUpdatedIKEv2CrendentialsCalled = false
        getUpdatedServerConfigCalled = false
        selectedServerCredentialsTypeCalled = false
        updateServerConfigCalled = false
    }
}
