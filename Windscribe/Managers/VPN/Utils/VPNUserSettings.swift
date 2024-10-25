//
//  VPNUserSettings.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//
import NetworkExtension

struct VPNUserSettings {
    let killSwitch: Bool
    let allowLane: Bool
    let isRFC: Bool
    let isCircumventCensorshipEnabled: Bool
    let onDemandRules: [NEOnDemandRule]?
}

struct OpenVPNConfiguration {
    let result: Bool
    let configUsername: String?
    let configPassword: String?
    let configFilePath: String?
    let configData: Data?
}
