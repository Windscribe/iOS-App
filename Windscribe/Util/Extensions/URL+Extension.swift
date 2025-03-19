//
//  URL+Extension.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-18.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

extension URL: Identifiable {
    public var id: String { absoluteString }
}
