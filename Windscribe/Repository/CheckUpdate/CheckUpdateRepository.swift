//
//  CheckUpdateRepository.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-13.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol CheckUpdateRepository {
    var updateAvailable: CurrentValueSubject<CheckUpdateModel?, Never> { get }
    func checkForUpdate()
}
