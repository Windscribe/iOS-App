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
    /// When true the update is mandatory — the UI must show an undismissable
    /// prompt that sends the user to the App Store.
    let force: Bool

    enum OuterKeys: String, CodingKey {
        case data
    }

    enum DataKeys: String, CodingKey {
        case updateNeededFlag = "update_needed_flag"
        case latestVersion = "latest_version"
        case latestBuild = "latest_build"
        case supported
        case updateUrl = "update_url"
        case force = "force_upgrade"
    }

    init(from decoder: Decoder) throws {
        let outer = try decoder.container(keyedBy: OuterKeys.self)
        let data = try outer.nestedContainer(keyedBy: DataKeys.self, forKey: .data)
        updateAvailable = (try data.decodeIfPresent(Int.self, forKey: .updateNeededFlag) ?? 0) == 1
        latestVersion = try data.decodeIfPresent(String.self, forKey: .latestVersion)
        latestBuild = try data.decodeIfPresent(Int.self, forKey: .latestBuild)
        supported = (try data.decodeIfPresent(Int.self, forKey: .supported) ?? 1) == 1
        updateUrl = try data.decodeIfPresent(String.self, forKey: .updateUrl)
        // Accept either bool or 0/1 int for backend flexibility; default false.
        if let asBool = try? data.decodeIfPresent(Bool.self, forKey: .force) {
            force = asBool
        } else if let asInt = try? data.decodeIfPresent(Int.self, forKey: .force) {
            force = asInt == 1
        } else {
            force = false
        }
    }

    init(updateAvailable: Bool, latestVersion: String?, force: Bool = false) {
        self.updateAvailable = updateAvailable
        self.latestVersion = latestVersion
        self.latestBuild = nil
        self.supported = true
        self.updateUrl = nil
        self.force = force
    }
}
