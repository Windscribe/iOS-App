//
//  APIManagerImpl+VPN.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension APIManagerImpl {
    func getStaticIpList() async throws -> StaticIPList {
        guard let sessionAuth = userRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        guard await UIDevice.current.identifierForVendor?.uuidString != nil else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: StaticIPList.self) { completion in
            self.api.staticIps(sessionAuth, version: 2, callback: completion)
        }
    }

    func getServerList(languageCode: String, revision: String, isPro: Bool, alcList: [String]) async throws -> ServerList {
        return try await apiUtil.makeApiCall(modalType: ServerList.self) { completion in
            self.api.serverLocations(languageCode, revision: revision, isPro: isPro, alcList: alcList, callback: completion)
        }
    }

    func getOpenVPNServerConfig(openVPNVersion _: String) async throws -> String {
        guard let sessionAuth = userRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: String.self) { completion in
            self.api.serverConfigs(sessionAuth, callback: completion)
        }
    }

    func getOpenVPNServerCredentials() async throws -> OpenVPNServerCredentials {
        guard let sessionAuth = userRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: OpenVPNServerCredentials.self) { completion in
            self.api.serverCredentials(sessionAuth, isOpenVpnProtocol: true, callback: completion)
        }
    }

    func getIKEv2ServerCredentials() async throws -> IKEv2ServerCredentials {
        guard let sessionAuth = userRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: IKEv2ServerCredentials.self) { completion in
            self.api.serverCredentials(sessionAuth, isOpenVpnProtocol: false, callback: completion)
        }
    }

    func getPortMap(version: Int, forceProtocols: [String]) async throws -> PortMapList {
        guard let sessionAuth = userRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: PortMapList.self) { completion in
            self.api.portMap(sessionAuth, version: UInt32(version), forceProtocols: forceProtocols, callback: completion)
        }
    }
}
