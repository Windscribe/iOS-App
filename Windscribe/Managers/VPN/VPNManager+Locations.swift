//
//  VPNManager+Locations.swift
//  Windscribe
//
//  Created by Andre Fonseca on 08/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

extension VPNManager {
    func saveLastSelectedLocation(with locationID: String) {
        preferences.saveLasteSelectedLocation(with locationID: String)
    }
    
    func saveBestLocation(with locationID: String) {
        preferences.saveBestLocation(with locationID: String)
    }
}
