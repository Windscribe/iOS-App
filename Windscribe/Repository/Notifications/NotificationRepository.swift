//
//  NotificationRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol NotificationRepository {
    var notices: CurrentValueSubject<[NoticeModel], Never> { get }
    var readNotices: CurrentValueSubject<[Int], Never> { get }
    func getUpdatedNotifications() async throws -> [NoticeModel]
    func loadNotifications() async
    func readNotice(with id: Int)
}
