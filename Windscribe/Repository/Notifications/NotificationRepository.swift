//
//  NotificationRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol NotificationRepository {
    var notices: BehaviorSubject<[Notice]> { get }
    func getUpdatedNotifications() -> Single<[Notice]>
    func loadNotifications()
}
