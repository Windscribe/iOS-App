//
//  EnterCredentialsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol EnterCredentialsViewModelType {
    var title: BehaviorSubject<String> { get }
    var username: BehaviorSubject<String> { get }
    var password: BehaviorSubject<String> { get }
    var isUpdating: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    func submit(title: String?, username: String?, password: String?)
    func setup(with customConfig: CustomConfigModel, isUpdating: Bool)
}

class EnterCredentialsViewModel: EnterCredentialsViewModelType {
    private var displayingCustomConfig: CustomConfigModel?

    let title = BehaviorSubject<String>(value: "")
    let username = BehaviorSubject<String>(value: "")
    let password = BehaviorSubject<String>(value: "")
    let isUpdating = BehaviorSubject<Bool>(value: false)
    let isDarkMode: BehaviorSubject<Bool>

    var vpnManager: VPNManager!
    var localDatabase: LocalDatabase!

    init(vpnManager: VPNManager!, localDatabase: LocalDatabase!, themeManager: ThemeManager) {
        self.vpnManager = vpnManager
        self.localDatabase = localDatabase
        isDarkMode = themeManager.darkTheme
    }

    func setup(with customConfig: CustomConfigModel, isUpdating: Bool) {
        displayingCustomConfig = customConfig
        title.onNext(customConfig.name ?? "")
        username.onNext(customConfig.username?.base64Decoded() ?? "")
        password.onNext(customConfig.password?.base64Decoded() ?? "")
        self.isUpdating.onNext(isUpdating)
    }

    func submit(title: String?, username: String?, password: String?) {
        guard let username = username?.base64Encoded(),
              let password = password?.base64Encoded(),
              let customConfigId = displayingCustomConfig?.id
        else { return }

        if let configTitle = title {
            localDatabase.updateCustomConfigName(customConfigId: customConfigId, name: configTitle)
        }

        guard let id = displayingCustomConfig?.id,
              let protocolType = displayingCustomConfig?.protocolType,
              let port = displayingCustomConfig?.port
        else { return }

        if !username.isEmpty {
            localDatabase.updateCustomConfigCredentials(customConfigId: customConfigId,
                                                        username: username,
                                                        password: password)
        }
        if !((try? isUpdating.value()) ?? false) {
            NotificationCenter.default.post(Notification(name: Notifications.configureVPN))
        }
    }
}
