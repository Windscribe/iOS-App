//
//  StaticIPTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-25.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class StaticIPNodeCellModel: BaseNodeCellViewModel {
    var displayingStaticIP: StaticIPModel?
    var latencyRepository = Assembler.resolve(LatencyRepository.self)

    init(displayingStaticIP: StaticIPModel?) {
        super.init()
        self.displayingStaticIP = displayingStaticIP
        if let bestNode = displayingStaticIP?.bestNode, let pingIP = bestNode.ip1, bestNode.forceDisconnect == false {
            minTime = latencyRepository.getPingData(ip: pingIP)?.latency ?? minTime
        }
    }

    override var name: String {
        displayingStaticIP?.cityName ?? ""
    }

    override var nickName: String {
        displayingStaticIP?.staticIP ?? ""
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

class StaticIPTableViewCell: BaseNodeCell {
    var staticIPCellViewModel: StaticIPNodeCellModel? {
        didSet {
            baseNodeCellViewModel = staticIPCellViewModel
        }
    }
}
