//
//  AdvanceRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-04-05.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol AdvanceRepository {
    func getForcedServer() -> String?
    func getPingType() -> Int32
}
