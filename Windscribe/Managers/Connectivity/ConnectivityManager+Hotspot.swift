//
//  ConnectivityImpl+Hotspot.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-06-06.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
import SystemConfiguration.CaptiveNetwork

extension ConnectivityManager {
    func getSsidFromNeHotspotHelper() async -> String? {
#if os(iOS)
        return await withCheckedContinuation { continuation in
            NEHotspotNetwork.fetchCurrent {
                continuation.resume(returning: $0?.ssid)
            }
        }
#else
        return nil
#endif
    }
}
