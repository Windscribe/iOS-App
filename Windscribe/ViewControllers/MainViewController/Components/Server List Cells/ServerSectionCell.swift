//
//  ServerSectionCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

protocol ServerSectionCellModelType: ServerCellModelType {
    var isExpanded: Bool { get }
    var isP2pHidden: Bool { get }
    var displayingServer: ServerModel? { get }
    func setIsExpanded(_ value: Bool)

    func update(serverModel: ServerModel?,
                isPremium: Bool,
                isDarkMode: Bool)
}

class ServerSectionCellModel: ServerSectionCellModelType {
    var isDarkMode: Bool = false
    var isExpanded: Bool = false
    var isPremium: Bool = false
    var showServerHealth: Bool = DefaultValues.showServerHealth

    var displayingServer: ServerModel?

    var name: String {
        displayingServer?.name ?? ""
    }

    var iconAspect: UIView.ContentMode { .scaleAspectFill }
    var iconImage: UIImage? {
        guard let countryCode = displayingServer?.countryCode else { return nil }
        return UIImage(named: "\(countryCode)-s")
    }

    var shouldTintIcon: Bool { false }

    var actionImage: UIImage? {
        UIImage(named: !isExpanded ? ImagesAsset.cellExpand : ImagesAsset.cellCollapse)?
            .withRenderingMode(.alwaysTemplate)
    }

    var iconSize: CGFloat = 20.0

    var actionSize: CGFloat = 16.0

    var actionRightOffset: CGFloat = 16.0

    var actionVisible: Bool = true

    var actionOpacity: Float {
        isExpanded ? 1.0 : 0.4
    }

    var nameOpacity: Float { 1.0 }

    var serverHealth: CGFloat {
        CGFloat(self.displayingServer?.getServerHealth() ?? 0)
    }

    var isP2pHidden: Bool {
        displayingServer?.p2p ?? false
    }

    var hasProLocked: Bool {
        guard let server = displayingServer else { return false }
        let hasNoPro = server.groups.first(where: { !$0.premiumOnly }) == nil
        return hasNoPro && !isPremium
    }

    func setIsExpanded(_ value: Bool) {
        isExpanded = value
    }

    func nameColor(for isDarkMode: Bool) -> UIColor {
        isExpanded ?
            .from( .textColor, isDarkMode) :
            .from( .infoColor, isDarkMode)
    }

    func update(serverModel: ServerModel?,
                isPremium: Bool,
                isDarkMode: Bool) {
        self.displayingServer = serverModel
        self.isPremium = isPremium
        self.isDarkMode = isDarkMode
    }
}

class ServerSectionCell: ServerListCell {
    var p2pIcon = UIImageView()

    var serverCellViewModel: ServerSectionCellModel? {
        didSet {
            viewModel = serverCellViewModel
            refreshUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = serverCellViewModel

        p2pIcon.contentMode = .scaleAspectFit
        p2pIcon.image = UIImage(named: ImagesAsset.p2p)
        p2pIcon.setImageColor(color: .white)
        p2pIcon.layer.opacity = 0.7
        contentView.addSubview(p2pIcon)

        refreshUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setCollapsed(collapsed: Bool, completion _: @escaping () -> Void = {}) {
        serverCellViewModel?.setIsExpanded(!collapsed)
        updateUI()
    }

    override func updateUI() {
        super.updateUI()
        guard let serverCellViewModel = serverCellViewModel else { return }
        p2pIcon.isHidden = serverCellViewModel.isP2pHidden
        p2pIcon.setImageColor(color: .from(.iconColor, viewModel?.isDarkMode ?? false))
    }

    override func updateLayout() {
        super.updateLayout()

        p2pIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // p2pIcon
            p2pIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            p2pIcon.rightAnchor.constraint(equalTo: actionImage.leftAnchor, constant: -14),
            p2pIcon.heightAnchor.constraint(equalToConstant: 16),
            p2pIcon.widthAnchor.constraint(equalToConstant: 16)
        ])
    }

    private func animateExpansion(completion: @escaping () -> Void = {}) {
        guard let serverCellViewModel = serverCellViewModel else { return }
        let isDarkMode = serverCellViewModel.isDarkMode
        UIView.animate(withDuration: 0.15, animations: {
            self.actionImage.layer.opacity = serverCellViewModel.actionOpacity
            self.nameLabel.textColor = serverCellViewModel.nameColor(for: isDarkMode)
        }, completion: { _ in
            completion()
        })
        UIView.transition(with: actionImage,
                          duration: 0.15,
                          options: .transitionCrossDissolve,
                          animations: { self.actionImage.image = serverCellViewModel.actionImage },
                          completion: nil)
    }

    func expand(completion: @escaping () -> Void = {}) {
        guard let serverCellViewModel = serverCellViewModel else { return }
        if !serverCellViewModel.isExpanded {
            serverCellViewModel.setIsExpanded(true)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }

    func collapse(completion: @escaping () -> Void = {}) {
        guard let serverCellViewModel = serverCellViewModel else { return }
        if serverCellViewModel.isExpanded {
            serverCellViewModel.setIsExpanded(false)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }
}
