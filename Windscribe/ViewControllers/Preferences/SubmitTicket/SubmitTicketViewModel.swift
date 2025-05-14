//
//  SubmitTicketViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

protocol SubmitTicketViewModel {
    var lookAndFeelRepository: LookAndFeelRepositoryType { get }
    var alertManager: AlertManagerV2 { get }
    var sessionManager: SessionManagerV2 { get }
    var isDarkMode: BehaviorSubject<Bool> { get }

    func sendTicket(email: String, subject: String, message: String, category: Int) -> Single<APIMessage>
}

class SubmitTicketViewModelImpl: SubmitTicketViewModel {
    var apiManager: APIManager
    var lookAndFeelRepository: LookAndFeelRepositoryType
    var alertManager: AlertManagerV2
    var sessionManager: SessionManagerV2
    let isDarkMode: BehaviorSubject<Bool>
    init(apiManager: APIManager, lookAndFeelRepository: LookAndFeelRepositoryType, alertManager: AlertManagerV2, sessionManager: SessionManagerV2) {
        self.apiManager = apiManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.alertManager = alertManager
        self.sessionManager = sessionManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
    }

    func sendTicket(email: String, subject: String, message: String, category: Int) -> Single<APIMessage> {
        let categoryLabel = TextsAsset.SubmitTicket.categories[category - 1]
        let currentDevice = UIDevice.current
        let deviceInfo = "Brand: Apple | Os: \(currentDevice.systemVersion) | Model: \(UIDevice.modelName)"
        let name = sessionManager.session?.userId ?? ""
        return apiManager.sendTicket(email: email, name: name, subject: subject, message: message, category: "\(category)", type: categoryLabel, channel: "app_ios", platform: deviceInfo)
    }
}
