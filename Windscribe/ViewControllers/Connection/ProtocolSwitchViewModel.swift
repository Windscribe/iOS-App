//
//  ProtocolSwitchViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ProtocolSwitchViewModelType {
    var isDarkMode: BehaviorSubject<Bool> {get}
    func isConnected() -> Bool
    func updateIsFromProtocol()
}

class ProtocolSwitchViewModel: ProtocolSwitchViewModelType {
    let isDarkMode: BehaviorSubject<Bool>
    private let vpnManager: VPNManager

    init(themeManager: ThemeManager, vpnManager: VPNManager) {
        self.vpnManager = vpnManager
        isDarkMode = themeManager.darkTheme
    }
    
    func isConnected() -> Bool {
        return vpnManager.isConnected()
    }
    
    func updateIsFromProtocol() {
        let isConnected = vpnManager.isConnected()
        vpnManager.isFromProtocolFailover = !isConnected
        vpnManager.isFromProtocolChange = isConnected
    }
}
