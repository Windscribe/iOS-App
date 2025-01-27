//
//  Bundle+Extension.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-07.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
