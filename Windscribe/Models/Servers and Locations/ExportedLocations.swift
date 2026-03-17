//
//  ExportedLocations.swift
//  Windscribe
//
//  Created by Andre Fonseca on 09/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

struct ExportedRegion: Codable {
    let id: Int
    let country: String
    let cities: [ExportedCity]
}

struct ExportedCity: Codable {
    let id: Int
    let name: String
    let nickname: String
}
