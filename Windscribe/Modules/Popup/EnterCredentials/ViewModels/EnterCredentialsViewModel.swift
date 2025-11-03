//
//  EnterCredentialsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol EnterCredentialsViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var title: String { get set }
    var username: String { get set }
    var password: String { get set }
    var isUpdating: Bool { get set }
    var saveCredentials: Bool { get set }
    var shouldDismiss: Bool { get set }

    func setConfig(_ config: CustomConfigModel, isUpdating: Bool)
    func submit()
    func cancel()
}

final class EnterCredentialsViewModelImpl: EnterCredentialsViewModel {
    @Published var isDarkMode: Bool = false
    @Published var title: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isUpdating: Bool = false
    @Published var saveCredentials: Bool = false
    @Published var shouldDismiss: Bool = false

    private var displayingCustomConfig: CustomConfigModel?
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let vpnManager: VPNManager
    private let localDatabase: LocalDatabase
    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         vpnManager: VPNManager,
         localDatabase: LocalDatabase) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.vpnManager = vpnManager
        self.localDatabase = localDatabase

        bind()
    }

    func setConfig(_ config: CustomConfigModel, isUpdating: Bool) {
        self.displayingCustomConfig = config
        self.isUpdating = isUpdating
        self.title = config.name ?? ""
        self.username = config.username?.base64Decoded() ?? ""
        self.password = config.password?.base64Decoded() ?? ""
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isDarkMode = $0
            }
            .store(in: &cancellables)
    }

    func submit() {
        guard  let customConfigId = displayingCustomConfig?.id else {
            logger.logE("EnterCredentialsViewModel", "Submit failed - missing required data")
            return
        }

        let username = username.base64Encoded()
        let password = password.base64Encoded()

        logger.logD("EnterCredentialsViewModel", "Submitting credentials for config: \(customConfigId)")

        // Update config name if title is provided
        if !title.isEmpty {
            localDatabase.updateCustomConfigName(customConfigId: customConfigId, name: title)
        }

        // Validate config has required fields
        guard displayingCustomConfig?.id != nil,
              displayingCustomConfig?.protocolType != nil,
              displayingCustomConfig?.port != nil
        else {
            logger.logE("EnterCredentialsViewModel", "Submit failed - invalid config")
            return
        }

        // Update credentials if username is provided
        if !username.isEmpty {
            localDatabase.updateCustomConfigCredentials(customConfigId: customConfigId,
                                                        username: username,
                                                        password: password)
        }

        // Configure VPN if this is a new config (not updating)
        if !isUpdating {
            NotificationCenter.default.post(Notification(name: Notifications.configureVPN))
        }

        shouldDismiss = true
    }

    func cancel() {
        logger.logD("EnterCredentialsViewModel", "Cancelled credentials entry")
        shouldDismiss = true
    }
}
