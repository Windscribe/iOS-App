//
//  ConnectivityImpl+Hotspot.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-06-06.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
import SystemConfiguration.CaptiveNetwork

extension Connectivity {
    func getSsidFromNeHotspotHelper(completion: @escaping (String?) -> Void) {
        #if os(iOS)
            NEHotspotNetwork.fetchCurrent { network in
                if let ssid = network?.ssid {
                    completion(ssid)
                    return
                }
                completion(nil)
            }
        #else
            completion(nil)
        #endif
    }
}
