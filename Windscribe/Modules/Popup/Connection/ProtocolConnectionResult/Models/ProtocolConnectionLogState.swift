//
//  ProtocolConnectionLogState.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum ProtocolConnectionLogState {
    case initial
    case sending
    case sent
    case failed
}
