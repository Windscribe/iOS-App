//
//  StaticIPTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-25.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Swinject
import UIKit

class StaticIPNodeCellModel: BaseNodeCellViewModel {
    var displayingStaticIP: StaticIPModel?

    override var name: String {
        displayingStaticIP?.cityName ?? ""
    }

    override var nickName: String {
        displayingStaticIP?.staticIP ?? ""
    }

    override var iconAspect: UIView.ContentMode { .scaleAspectFit }
    override var iconImage: UIImage? {
        guard let staticIP = displayingStaticIP else {
            return UIImage(named: ImagesAsset.Servers.staticIP)?.withRenderingMode(.alwaysTemplate)
        }

        let iconName: String
        switch staticIP.ipType {
        case .datacenter:
            iconName = ImagesAsset.Servers.staticIPDatacenter
        case .residential:
            iconName = ImagesAsset.Servers.staticIPResidential
        case .unknown:
            iconName = ImagesAsset.Servers.staticIP
        }

        return UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
    }

    override var actionImage: UIImage? { nil }

    override var actionVisible: Bool { false }

    override var showServerNetLoad: Bool { false }

    func update(displayingStaticIP: StaticIPModel?,
                isDarkMode: Bool,
                latency: Int) {
        self.displayingStaticIP = displayingStaticIP
        self.isDarkMode = isDarkMode
        self.latency = latency
    }
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
