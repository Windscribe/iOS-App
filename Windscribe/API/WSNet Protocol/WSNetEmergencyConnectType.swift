//
//  WSNetEmergencyConnectType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 13/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//
protocol WSNetEmergencyConnectType {
    func getIpEndpoints() async -> [WSNetEmergencyConnectEndpoint]
    func getUsername() -> String
    func getPassword() -> String
    func getOvpnConfig() -> String
}

extension WSNetEmergencyConnect: WSNetEmergencyConnectType {
    func getIpEndpoints() async -> [WSNetEmergencyConnectEndpoint] {
        await withCheckedContinuation { continuation in
            getIpEndpoints { endpoints in
                continuation.resume(returning: endpoints)
            }
        }
    }

    func getUsername() -> String { username() }
    func getPassword() -> String { password() }
    func getOvpnConfig() -> String { ovpnConfig() }
}
