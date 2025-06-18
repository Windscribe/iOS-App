//
//  CustomConfigCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 03/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class CustomConfigCellModel: BaseNodeCellViewModel {
    var displayingCustomConfig: CustomConfigModel?
    var latencyRepository = Assembler.resolve(LatencyRepository.self)

    init(displayingCustomConfig: CustomConfigModel?) {
        super.init()
        self.displayingCustomConfig = displayingCustomConfig
        if let pingIP = displayingCustomConfig?.serverAddress {
            minTime = latencyRepository.getPingData(ip: pingIP)?.latency ?? minTime
        }
    }
    override var name: String {
        displayingCustomConfig?.name ?? ""
    }

    override var nickName: String {
        ""
    }

    override var showServerHealth: Bool { false }
    override var clipIcon: Bool { false }
    override var iconAspect: UIView.ContentMode { .scaleAspectFit }

    override var iconImage: UIImage? {
        if displayingCustomConfig?.protocolType == TextsAsset.wireGuard {
            return UIImage(named: ImagesAsset.customConfigWG)?.withRenderingMode(.alwaysTemplate)
        } else if TextsAsset.General.openVpnProtocols.contains(displayingCustomConfig?.protocolType ?? "") {
            return UIImage(named: ImagesAsset.customConfigOVPN)?.withRenderingMode(.alwaysTemplate)
        }
        return UIImage(named: ImagesAsset.Servers.config)?.withRenderingMode(.alwaysTemplate)
    }

    override var actionImage: UIImage? {
        if areMissingCredentials {
            return UIImage(named: ImagesAsset.missingCredentials)?.withRenderingMode(.alwaysTemplate)
        }
        return nil
    }

    override var actionSize: CGFloat {
        areMissingCredentials ? 20.0 : 0.0
    }

    override var actionRightOffset: CGFloat {
        areMissingCredentials ? 24.0 : 0.0
    }

    override var isSignalVisible: Bool { !areMissingCredentials }

    private var areMissingCredentials: Bool {
        ((displayingCustomConfig?.username ?? "").isEmpty || (displayingCustomConfig?.password ?? "").isEmpty) && (displayingCustomConfig?.authRequired ?? false)
    }
}

class CustomConfigCell: BaseNodeCell {
    var customConfigCellViewModel: CustomConfigCellModel? {
        didSet {
            baseNodeCellViewModel = customConfigCellViewModel
        }
    }
}
