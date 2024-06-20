//
//  APIManagerImpl+VPN.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
extension APIManagerImpl {
    func getStaticIpList() -> Single<StaticIPList> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        guard let deviceID = UIDevice.current.identifierForVendor?.uuidString else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: StaticIPList.self) { completion in
            self.api.staticIps(sessionAuth, platform: APIParameterValues.platform, deviceId: deviceID, callback: completion)
        }
    }

    func getServerList(languageCode: String, revision: String, isPro: Bool, alcList: [String]) -> Single<ServerList> {
        return makeApiCall(modalType: ServerList.self) { completion in
            self.api.serverLocations(languageCode, revision: revision, isPro: isPro, alcList: alcList, callback: completion)
        }
    }

    func getOpenVPNServerConfig(openVPNVersion: String) -> Single<String> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: String.self) { completion in
            self.api.serverConfigs(sessionAuth, ovpnVersion: openVPNVersion, callback: completion)
        }
    }

    func getOpenVPNServerCredentials() -> Single<OpenVPNServerCredentials> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: OpenVPNServerCredentials.self) { completion in
            self.api.serverCredentials(sessionAuth, isOpenVpnProtocol: true, callback: completion)
        }
    }

    func getIKEv2ServerCredentials() -> Single<IKEv2ServerCredentials> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: IKEv2ServerCredentials.self) { completion in
            self.api.serverCredentials(sessionAuth, isOpenVpnProtocol: false, callback: completion)
        }
    }

    func getPortMap(version: Int, forceProtocols: [String]) -> Single<PortMapList> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: PortMapList.self) { completion in
            self.api.portMap(sessionAuth, version: UInt32(version), forceProtocols: forceProtocols, callback: completion)
        }
    }
}
