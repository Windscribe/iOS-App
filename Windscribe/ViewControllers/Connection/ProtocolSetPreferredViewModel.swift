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
    var sessionManager: SessionManagerV2
    var apiManager: APIManager
    var protocolManager: ProtocolManagerType
    var disposeBag = DisposeBag()
    var submitLogState = BehaviorSubject(value: SubmitLogState.initial)
    let isDarkMode: BehaviorSubject<Bool>

    init(alertManager: AlertManagerV2, type: ProtocolViewType, securedNetwork: SecuredNetworkRepository, localDatabase: LocalDatabase, apiManager: APIManager, sessionManager: SessionManagerV2, logger: FileLogger, lookAndFeelRepository: LookAndFeelRepositoryType, protocolManager: ProtocolManagerType) {
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
        logger.getLogData()
            .flatMap { fileData in
                var debugUsername = ""
                if let session = self.sessionManager.session {
                    debugUsername = session.username
                }
                if let session = self.sessionManager.session, session.isUserGhost == true {
                    debugUsername = "ghost_\(session.userId)"
                }
                return self.apiManager.sendDebugLog(username: debugUsername, log: fileData)
            }
            .subscribe(onSuccess: { [self] _ in
                submitLogState.onNext(.sent)
            }, onFailure: { [self] _ in
                submitLogState.onNext(.failed)
            }).disposed(by: disposeBag)
    }

    func getProtocolName() async -> String {
        await protocolManager.getNextProtocol().protocolName
    }
}
