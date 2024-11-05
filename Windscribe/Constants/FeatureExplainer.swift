//
//  FeatureExplainer.swift
//  Windscribe
//
//  Created by Thomas on 21/08/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

enum FeatureExplainer {
    case connectionModes
    case fiwall
    case allowLan
    case connectedDNS

    func getUrl() -> String {
        var endpoint = ""
        switch self {
        case .connectionModes:
            endpoint = "features/flexible-connectivity"
        case .fiwall:
            endpoint = "features/firewall"
        case .allowLan:
            endpoint = "features/lan-traffic"
        case .connectedDNS:
            endpoint = "features/flexible-dns"
        }
        return Links.base + endpoint
    }
}
