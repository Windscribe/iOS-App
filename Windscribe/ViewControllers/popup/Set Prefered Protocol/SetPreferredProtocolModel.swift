//
//  SetPreferredProtocolModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 09/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol SetPreferredProtocolModelType {
    var networkNameLabel: BehaviorSubject<String> { get }
    var title: BehaviorSubject<String> { get }
    func action()
    func cancel()
}

class SetPreferredProtocolModel: SetPreferredProtocolModelType {
    // MARK: - Dependencies

    let connectivity: Connectivity
    let networkRepository: SecuredNetworkRepository
    let logger: FileLogger

    let disposeBag = DisposeBag()
    let networkNameLabel = BehaviorSubject<String>(value: "")
    let title = BehaviorSubject<String>(value: "")

    init(connectivity: Connectivity, networkRepository: SecuredNetworkRepository, logger: FileLogger) {
        self.connectivity = connectivity
        self.networkRepository = networkRepository
        self.logger = logger
        load()
    }

    private func load() {
        connectivity.network.subscribe(onNext: { [self] network in
            if network.networkType == .wifi, let name = network.name {
                self.networkNameLabel.onNext(name)
                let protocolType = networkRepository.getCurrentNetwork()?.protocolType ?? ""
                self.title.onNext(TextsAsset.SetPreferredProtocolPopup.title(protocolType: protocolType))
            }
        }).disposed(by: disposeBag)
    }

    func action() {
        if let wifiNetwork = networkRepository.getCurrentNetwork() {
            logger.logD(self, "User tapped Set as Preferred button.")
            networkRepository.setNetworkPreferredProtocol(network: wifiNetwork)
        }
    }

    func cancel() {
        if let wifiNetwork = networkRepository.getCurrentNetwork() {
            logger.logD(self, "User canceled setting Preferred Wifi.")
            if wifiNetwork.popupDismissCount >= 1 {
                networkRepository.setNetworkDontAskAgainForPreferredProtocol(network: wifiNetwork)
            } else {
                networkRepository.incrementNetworkDismissCount(network: wifiNetwork)
            }
        }
    }
}
