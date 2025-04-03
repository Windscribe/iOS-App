//
//  ServerSectionCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

protocol ServerSectionCellModelType: ServerCellModelType {
    var isExpanded: Bool { get }
    var displayingServer: ServerModel? { get }
    func setIsExpanded(_ value: Bool)
    func setDisplayingServer(_ value: ServerModel?)
}

class ServerSectionCellModel: ServerSectionCellModelType {
    var isExpanded: Bool = false

    var displayingServer: ServerModel?

    var name: String {
        displayingServer?.name ?? ""
    }

    var iconImage: UIImage? {
        guard let countryCode = displayingServer?.countryCode else { return nil }
        return UIImage(named: "\(countryCode)-s")
    }

    var actionImage: UIImage? {
        UIImage(named: !isExpanded ? ImagesAsset.cellExpand : ImagesAsset.cellCollapse)
    }

    var iconSize: CGFloat = 20.0

    var actionSize: CGFloat = 16.0

    var actionRightOffset: CGFloat = 24.0

    var actionOpacity: Float {
        isExpanded ? 1.0 : 0.4
    }

    var nameOpacity: Float {
        isExpanded ? 1.0 : 0.7
    }

    var serverHealth: CGFloat {
        CGFloat(self.displayingServer?.getServerHealth() ?? 0)
    }

    func setIsExpanded(_ value: Bool) {
        isExpanded = value
    }

    func setDisplayingServer(_ value: ServerModel?) {
        displayingServer = value
    }
}

class ServerSectionCell: ServerListCell {
    var serverCellViewModel = ServerSectionCellModel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = serverCellViewModel
        updateUI()
        updateLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateServerModel(_ value: ServerModel?) {
        serverCellViewModel.setDisplayingServer(value)
        updateUI()
    }

    func setCollapsed(collapsed: Bool, completion _: @escaping () -> Void = {}) {
        serverCellViewModel.setIsExpanded(!collapsed)
        updateUI()
    }

    private func animateExpansion(completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.35, animations: {
            self.nameLabel.layer.opacity = self.serverCellViewModel.nameOpacity
            self.actionImage.layer.opacity = self.serverCellViewModel.actionOpacity
        }, completion: { _ in
            completion()
        })
        UIView.transition(with: actionImage,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { self.actionImage.image = self.serverCellViewModel.actionImage },
                          completion: nil)
    }

    func expand(completion: @escaping () -> Void = {}) {
        if !serverCellViewModel.isExpanded {
            serverCellViewModel.setIsExpanded(true)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }

    func collapse(completion: @escaping () -> Void = {}) {
        if serverCellViewModel.isExpanded {
            serverCellViewModel.setIsExpanded(false)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }
}
