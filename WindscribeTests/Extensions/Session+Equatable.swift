//
//  Session+Equatable.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/03/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

@testable import Windscribe

extension SessionModel: @retroactive Equatable {
    public static func == (lhs: SessionModel, rhs: SessionModel) -> Bool {
        lhs.username == rhs.username &&
        lhs.userId == rhs.userId &&
        lhs.sessionAuthHash == rhs.sessionAuthHash
    }
}
