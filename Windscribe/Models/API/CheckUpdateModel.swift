//
//  CheckUpdateModel.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-13.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

struct CheckUpdateModel: Decodable {
    let updateAvailable: Bool
    let latestVersion: String?
    let latestBuild: Int?
    let supported: Bool
    let updateUrl: String?

    enum OuterKeys: String, CodingKey {
        case data
    }

    enum DataKeys: String, CodingKey {
        case updateNeededFlag = "update_needed_flag"
        case latestVersion = "latest_version"
        case latestBuild = "latest_build"
        case supported
        case updateUrl = "update_url"
    }

    init(from decoder: Decoder) throws {
        let outer = try decoder.container(keyedBy: OuterKeys.self)
        let data = try outer.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        updateAvailable = (try data.decodeIfPresent(Int.self, forKey: .updateNeededFlag) ?? 0) == 1
        latestVersion = try data.decodeIfPresent(String.self, forKey: .latestVersion)
        latestBuild = try data.decodeIfPresent(Int.self, forKey: .latestBuild)
        supported = (try data.decodeIfPresent(Int.self, forKey: .supported) ?? 1) == 1
        updateUrl = try data.decodeIfPresent(String.self, forKey: .updateUrl)
    }

    init(updateAvailable: Bool, latestVersion: String?) {
        self.updateAvailable = updateAvailable
        self.latestVersion = latestVersion
        self.latestBuild = nil
        self.supported = true
        self.updateUrl = nil
    }
}
