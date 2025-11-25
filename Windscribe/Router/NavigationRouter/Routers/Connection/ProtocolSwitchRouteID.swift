//
//  ProtocolSwitchRouteID.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum ProtocolSwitchRouteID: Int, BaseRouteID, CaseIterable {
    case protocolConnectionResult = 0
    case protocolConnectionDebug

    var id: ProtocolSwitchRouteID { self }
}
