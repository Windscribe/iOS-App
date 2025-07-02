//
//  NodeTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Realm
import RealmSwift
import RxSwift
import Swinject
import UIKit

protocol NodeTableViewCellModelType: BaseNodeCellViewModelType {
    var displayingGroup: GroupModel? { get }
    var isProLocked: Bool { get }
    var isSpeedIconVisible: Bool { get }
}

class NodeTableViewCellModel: BaseNodeCellViewModel, NodeTableViewCellModelType {
    var sessionManager = Assembler.resolve(SessionManaging.self)
    var latencyRepository = Assembler.resolve(LatencyRepository.self)

    var displayingGroup: GroupModel?
    var displayingNodeServer: ServerModel?

    init(displayingGroup: GroupModel?) {
        super.init()
        self.displayingGroup = displayingGroup
        if let pingIP = displayingGroup?.pingIp {
            minTime = latencyRepository.getPingData(ip: pingIP)?.latency ?? minTime
        }
        isFavourited = isNodeFavorited()
    }

    override var serverHealth: CGFloat {
        CGFloat(self.displayingGroup?.health ?? 0)
    }

    override var groupId: String {
        if let id = displayingGroup?.id {
            return "\(id)"
        }
        return ""
    }

    override var name: String {
        displayingGroup?.city ?? ""
    }

    override var nickName: String {
        displayingGroup?.nick ?? ""
    }

    override var iconImage: UIImage? {
        !isProLocked ? super.iconImage : UIImage(named: ImagesAsset.proCityImage)?.withRenderingMode(.alwaysTemplate)
    }

    var isProLocked: Bool {
        guard let group = displayingGroup else { return false }
        return group.premiumOnly &&
        !(sessionManager.session?.isPremium ?? false)
    }

    var isSpeedIconVisible: Bool {
        displayingGroup?.linkSpeed == "10000"
    }

    override func favoriteSelected() {
        if isFavourited {
            let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.localDB.removeFavourite(groupId: "\(self.groupId)")
            }
            AlertManager.shared.showAlert(title: TextsAsset.Favorites.removeTitle,
                                          message: TextsAsset.Favorites.removeMessage,
                                          buttonText: TextsAsset.cancel, actions: [yesAction])
        } else {
            localDB.saveFavourite(favourite: Favourite(id: "\(self.groupId)")).disposed(by: disposeBag)
        }
    }
}

class NodeTableViewCell: BaseNodeCell {
    var speedIcon = UIImageView()

    var nodeCellViewModel: NodeTableViewCellModelType? {
        didSet {
            baseNodeCellViewModel = nodeCellViewModel
            speedIcon.isHidden = !(nodeCellViewModel?.isSpeedIconVisible ?? true)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        speedIcon.image = UIImage(named: ImagesAsset.tenGig)
        speedIcon.layer.opacity = 0.8
        speedIcon.setImageColor(color: .white)
        iconsStackView.insertArrangedSubview(speedIcon, at: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode.subscribe(onNext: { isDarkMode in
            self.speedIcon.setImageColor(color: .from(.iconColor, isDarkMode))
        }).disposed(by: disposeBag)
    }

    override func updateLayout() {
        super.updateLayout()

        speedIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // speedIcon
            speedIcon.centerYAnchor.constraint(equalTo: iconsStackView.centerYAnchor, constant: 1),
            speedIcon.heightAnchor.constraint(equalToConstant: 20),
            speedIcon.widthAnchor.constraint(equalToConstant: 20)
        ])
    }

    override func updateUI() {
        super.updateUI()
        if nodeCellViewModel?.isProLocked ?? false {
            icon.setImageColor(color: .proStarColor)
        }
    }

    override func setPressState(active: Bool) {
        super.setPressState(active: active)
        DispatchQueue.main.asyncAfter(deadline: .now() + (active ? 0.0 : 0.3)) { [weak self] in
            self?.speedIcon.layer.opacity = active ? 1 : 0.8
        }
    }
}
