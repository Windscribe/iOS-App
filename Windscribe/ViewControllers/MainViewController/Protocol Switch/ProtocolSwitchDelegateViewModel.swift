//
//  ProtocolSwitchDelegateViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ProtocolSwitchDelegateViewModelType: ProtocolSwitchVCDelegate {
    var disableVPNTrigger: PublishSubject<Void> { get }
}

class ProtocolSwitchDelegateViewModel: ProtocolSwitchDelegateViewModelType {
    var disableVPNTrigger = PublishSubject<Void>()

    init() { }
}

extension ProtocolSwitchDelegateViewModel: ProtocolSwitchVCDelegate {
    func disconnectFromFailOver() {
        disableVPNTrigger.onNext(())
    }
}

protocol ProtocolSwitchVCDelegate: AnyObject {
    func disconnectFromFailOver()
}
