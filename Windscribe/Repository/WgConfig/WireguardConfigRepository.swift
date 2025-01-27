//
//  WireguardConfigRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol WireguardConfigRepository {
    func getCredentials() -> Completable
}
