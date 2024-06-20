//
//  Realm+Extension.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-06.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {
    public func safeWrite(_ block: (() throws -> Void)) throws {
        if isInWriteTransaction {
            try block()
        } else {
            try write(block)
        }
    }
}
