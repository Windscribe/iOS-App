//
//  Latency.swift
//  Windscribe
//
//  Created by Bushra Sagir on 27/05/23.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

struct Latency: Codable {
    let rtt: String
}

enum LatencyType {
    case servers
    case staticIp
    case config
}

struct LoadLatencyInfo {
    let force: Bool
    let selectBestLocation: Bool
    let connectToBestLocation: Bool
}
