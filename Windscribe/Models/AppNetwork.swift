//
//  AppNetwork.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-09.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum NetworkStatus {
    case connected
    case disconnected
    case requiresVPN
}
enum NetworkType {
    case cellular
    case wifi
    case none
}

struct AppNetwork: CustomStringConvertible {
    let status: NetworkStatus
    let networkType: NetworkType
    let name: String?
    let isVPN: Bool
    init(_ status: NetworkStatus, networkType: NetworkType = .none, name: String? = nil, isVPN: Bool = false) {
        self.status = status
        self.networkType = networkType
        self.name = name
        self.isVPN = isVPN
    }
    var description: String {
        return "Internet Connection [Status:\(status) NetworkType:\(networkType) Name:\(name ?? "Unknown") isVPN:\(isVPN)]"
    }
}
