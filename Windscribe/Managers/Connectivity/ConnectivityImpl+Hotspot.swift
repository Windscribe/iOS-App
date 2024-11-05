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
            if #available(iOS 14.0, *) {
                NEHotspotNetwork.fetchCurrent { network in
                    if let ssid = network?.ssid {
                        completion(ssid)
                        return
                    }
                    completion(nil)
                }
            } else {
                if let interfaces = CNCopySupportedInterfaces() as? [CFString] {
                    for interface in interfaces {
                        if let networkInfo = CNCopyCurrentNetworkInfo(interface) as NSDictionary? {
                            completion(networkInfo[kCNNetworkInfoKeySSID as String] as? String)
                            return
                        }
                    }
                }
                completion(nil)
            }
        #else
            completion(nil)
        #endif
    }
}
