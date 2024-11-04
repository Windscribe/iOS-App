//
//  SessionManagerV2.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
protocol SessionManagerV2 {
    var session: Session? { get }
    func setSessionTimer()
    func listenForSessionChanges()
    func logoutUser()
    func checkForSessionChange()
    func keepSessionUpdated()
    func canAccesstoProLocation() -> Bool
    func getUppdatedSession() -> Single<Session>
}
