//
//  UserRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
protocol UserRepository {
    var sessionAuth: String? { get }
    var user: BehaviorSubject<User?> { get }
    func getUpdatedUser() -> Single<User>
    func login(session: Session)
}
