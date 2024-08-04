//
//  ConnectivityImpl+Hotspot.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-06-06.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
extension Connectivity {
    func getSsidFromNeHotspotHelper(completion: @escaping (String?) -> Void) {
#if os(iOS)
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                if let ssid = network?.ssid {
                    completion(ssid)
                } else {
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
#else
        completion(nil)
#endif
    }
}
