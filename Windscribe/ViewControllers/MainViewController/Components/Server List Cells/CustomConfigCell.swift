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

    override var actionImage: UIImage? {
        nil
    }

    override var actionSize: CGFloat {
        0.0
    }

    override var actionRightOffset: CGFloat {
        0.0
    }
}

class CustomConfigCell: BaseNodeCell {
    var customConfigCellViewModel: CustomConfigCellModel? {
        didSet {
            baseNodeCellViewModel = customConfigCellViewModel
        }
    }
}
