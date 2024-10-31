//
//  VPNUserSettings.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//
import NetworkExtension
import WireGuardKit
enum LocationType {
    case server
    case staticIP
    case custom
}

struct VPNUserSettings: CustomStringConvertible {
    let killSwitch: Bool
    let allowLane: Bool
    let isRFC: Bool
    let isCircumventCensorshipEnabled: Bool
    let onDemandRules: [NEOnDemandRule]?
    var description: String {
        return "User Settings: [KillSwitch: \(killSwitch) allowLan: \(allowLane), isRfc: \(isRFC), CircumventCensorship: \(isCircumventCensorshipEnabled)]"
    }
}

struct OpenVPNConfiguration: VPNConfiguration {
    let proto: String
    let username: String?
    let password: String?
    let path: String
    let data: Data
    var description: String {
        return "OpenVPN: [proto: \(proto) path: \(path) username: \(username ?? "N/A") password: \(password ?? "N/A")]"
    }
}

struct IKEv2VPNConfiguration: VPNConfiguration {
    let username: String
    let hostname: String
    let ip: String
    var description: String {
        return "IKEv2: [username: \(username) ip: \(ip) hostname: \(hostname)]"
    }
}

struct WireguardVPNConfiguration: VPNConfiguration {
    let content: TunnelConfiguration
    var description: String {
        return "Wireguard: [content: \(content)"
    }
}

protocol VPNConfiguration: CustomStringConvertible {}
