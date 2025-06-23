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
        if let bestNode = displayingStaticIP?.bestNode, bestNode.forceDisconnect == false {
            minTime = latencyRepository.getPingData(ip: bestNode.ip1)?.latency ?? minTime
        }
    }

    override var name: String {
        displayingStaticIP?.cityName ?? ""
    }

    override var nickName: String {
        displayingStaticIP?.staticIP ?? ""
    }

    override var iconAspect: UIView.ContentMode { .scaleAspectFit }
    override var iconImage: UIImage? {
        UIImage(named: ImagesAsset.Servers.staticIP)?.withRenderingMode(.alwaysTemplate)
    }

    override var actionImage: UIImage? { nil }

    override var actionVisible: Bool { false }
}

class StaticIPTableViewCell: BaseNodeCell {
    var staticIPCellViewModel: StaticIPNodeCellModel? {
        didSet {
            baseNodeCellViewModel = staticIPCellViewModel
        }
    }

    override func updateUI() {
        super.updateUI()
        nameInfoStackView.axis = .vertical
        nameInfoStackView.spacing = 0
        healthCircle.health = -1
        circleView.isHidden = true
    }
}
