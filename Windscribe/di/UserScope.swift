//
//  UserScope.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-06-07.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

extension ObjectScope {
    /// Add dependencies that needds to be reacreated on user logout.
    static let userScope = ObjectScope(storageFactory: PermanentStorage.init)
}
