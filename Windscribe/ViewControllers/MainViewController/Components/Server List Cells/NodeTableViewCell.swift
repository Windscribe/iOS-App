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
    var sessionManager = Assembler.resolve(SessionManagerV2.self)
    var latencyRepository = Assembler.resolve(LatencyRepository.self)

    var displayingGroup: GroupModel?
    var displayingNodeServer: ServerModel?

    init(displayingGroup: GroupModel?, displayingNodeServer: ServerModel?) {
        super.init()
        self.displayingGroup = displayingGroup
        self.displayingNodeServer = displayingNodeServer
        if let pingIP = displayingGroup?.pingIp {
            minTime = latencyRepository.getPingData(ip: pingIP)?.latency ?? minTime
        }
        if let groupId = displayingGroup?.id {
            isFavourited = favNodes.map { $0.groupId }.contains("\(groupId)")
        }
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

    override var actionImage: UIImage? {
        !isProLocked ? super.actionImage : UIImage(named: ImagesAsset.proNodeIcon)?.withRenderingMode(.alwaysTemplate)
    }

    var isProLocked: Bool {
        return(displayingGroup?.premiumOnly ?? false) &&
        !(sessionManager.session?.isPremium ?? false)
    }

    var isSpeedIconVisible: Bool {
        displayingGroup?.linkSpeed == "10000"
    }

    override func favoriteSelected() {
        if !isProLocked {
            guard let group = displayingGroup, let server = displayingNodeServer else { return }
            if isFavourited {
                let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { [weak self] _ in
                    guard let self = self else { return }
                    self.isFavourited = false
                    updateUISubject.onNext(())
                    if group.id >= 0,
                       let favNodeHostname = self.favNodes.filter({ $0.groupId == "\(self.groupId)" }).first?.hostname {
                        self.localDB.removeFavNode(hostName: favNodeHostname)
                    }
                }
                AlertManager.shared.showAlert(title: TextsAsset.Favorites.removeTitle,
                                              message: TextsAsset.Favorites.removeMessage,
                                              buttonText: TextsAsset.cancel, actions: [yesAction])
            } else {
                isFavourited = true
                updateUISubject.onNext(())
                if let bestNode = group.bestNode {
                    let favNode = FavNode(node: bestNode, group: group, server: server)
                    localDB.saveFavNode(favNode: favNode).disposed(by: disposeBag)
                }
            }
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
        contentView.addSubview(speedIcon)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode.subscribe(onNext: { _ in
            self.speedIcon.setImageColor(color: .white)
        }).disposed(by: disposeBag)
    }

    override func updateLayout() {
        super.updateLayout()

        speedIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // speedIcon
            speedIcon.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1),
            speedIcon.rightAnchor.constraint(equalTo: latencyLabel.leftAnchor, constant: -14),
            speedIcon.heightAnchor.constraint(equalToConstant: 20),
            speedIcon.widthAnchor.constraint(equalToConstant: 20)
        ])
    }

    override func setPressState(active: Bool) {
        super.setPressState(active: active)
        DispatchQueue.main.asyncAfter(deadline: .now() + (active ? 0.0 : 0.3)) { [weak self] in
            self?.speedIcon.layer.opacity = active ? 1 : 0.8
        }
    }
}
