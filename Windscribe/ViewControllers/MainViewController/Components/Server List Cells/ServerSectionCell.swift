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
    var isP2pHidden: Bool { get }
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

    var isP2pHidden: Bool {
        displayingServer?.p2p ?? false
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
    var p2pIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = serverCellViewModel

        p2pIcon.image = UIImage(named: ImagesAsset.p2p)
        p2pIcon.setImageColor(color: .white)
        p2pIcon.layer.opacity = 0.7
        contentView.addSubview(p2pIcon)

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

    override func updateUI() {
        super.updateUI()
        p2pIcon.isHidden = serverCellViewModel.isP2pHidden
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

    override func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode.subscribe(onNext: { isDark in
            self.p2pIcon.setImageColor(color: isDark ? .white : .nightBlue)
        }).disposed(by: disposeBag)
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
