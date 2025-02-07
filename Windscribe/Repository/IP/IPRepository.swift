//
//  IPRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol IPRepository {
    var ipState: BehaviorSubject<IPState?> { get }
    func getIp() -> Single<MyIP>
}
