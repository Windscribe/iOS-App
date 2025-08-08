//
//  ProtocolSetPreferredViewModel.swift
//  Windscribe
//
//  Created by Thomas on 03/10/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

enum SubmitLogState {
    case initial
    case sending
    case sent
    case failed
}

protocol ProtocolSetPreferredViewModelV2 {
    var alertManager: AlertManagerV2 { get }
    var securedNetwork: SecuredNetworkRepository { get }
    var localDatabase: LocalDatabase { get }
    var changeMessage: String { get }
    var failMessage: String { get }
    var failHeaderString: String { get }
    var type: ProtocolViewType { get set }
    var submitLogState: BehaviorSubject<SubmitLogState> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }

    func submitLog()
    func getSubHeader() -> String
    func getProtocolName() async -> String
}

class ProtocolSetPreferredViewModel: ProtocolSetPreferredViewModelV2 {
    let alertManager: AlertManagerV2
    var type: ProtocolViewType
    var securedNetwork: SecuredNetworkRepository
    var localDatabase: LocalDatabase
    var logger: FileLogger
    var sessionManager: SessionManaging
    var apiManager: APIManager
    var protocolManager: ProtocolManagerType
    var disposeBag = DisposeBag()
    var submitLogState = BehaviorSubject(value: SubmitLogState.initial)
    let isDarkMode: BehaviorSubject<Bool>

    init(alertManager: AlertManagerV2, type: ProtocolViewType, securedNetwork: SecuredNetworkRepository, localDatabase: LocalDatabase, apiManager: APIManager, sessionManager: SessionManaging, logger: FileLogger, lookAndFeelRepository: LookAndFeelRepositoryType, protocolManager: ProtocolManagerType) {
        self.alertManager = alertManager
        self.type = type
        self.securedNetwork = securedNetwork
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        self.sessionManager = sessionManager
        self.logger = logger
        self.protocolManager = protocolManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
    }

    let changeMessage = TextsAsset.SetPreferredProtocolPopup.changeMessage
    let failMessage = TextsAsset.SetPreferredProtocolPopup.failMessage
    let failHeaderString = TextsAsset.SetPreferredProtocolPopup.failHeaderString

    func getSubHeader() -> String {
        return type == .fail ? failMessage : changeMessage
    }

    func submitLog() {
        submitLogState.onNext(.sending)
        Task {
            do {
                let logData = try await logger.getLogData()

                let username = await MainActor.run {
                    var username = sessionManager.session?.username ?? ""
                    if let session = sessionManager.session, session.isUserGhost {
                        username = "ghost_\(session.userId)"
                    }
                    return username
                }

                _ = try await apiManager.sendDebugLog(username: username, log: logData)

                await MainActor.run {
                    submitLogState.onNext(.sent)
                }
            } catch {
                await MainActor.run {
                    submitLogState.onNext(.failed)
                }
            }
        }
    }

    func getProtocolName() async -> String {
        await protocolManager.getNextProtocol().protocolName
    }
}
