//
//  KeyChainDatabase.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-09.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol KeyChainDatabase {
    func save(username: String, password: String)
    func retrieve(username: String) -> Data?
    func isGhostAccountCreated() -> Bool
    func setGhostAccountCreated()
}
