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
    var isFavorite: Bool { get }
}

class NodeTableViewCellModel: BaseNodeCellViewModel, NodeTableViewCellModelType {
    var sessionManager = Assembler.resolve(SessionManager.self)
    var latencyRepository = Assembler.resolve(LatencyRepository.self)

    var displayingGroup: GroupModel?
    var isFavorite: Bool

    init(displayingGroup: GroupModel?, isFavorite: Bool = false) {
        self.isFavorite = isFavorite
        super.init()
        self.displayingGroup = displayingGroup
        if let pingIP = displayingGroup?.pingIp {
            minTime = latencyRepository.getPingData(ip: pingIP)?.latency ?? minTime
        }
        isFavourited = isNodeFavorited()
    }

    override var isSignalVisible: Bool { !isDisabled }
    override var isDisabled: Bool {
        return !(displayingGroup?.canConnect() ?? true)
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

    override var iconSize: CGFloat {
        if isFavorite { return 20.0 }
        if isProLocked { return super.iconSize }
        if isSpeedIconVisible { return 16.0 }
        return 20.0
    }

    override var iconImage: UIImage? {
        if isFavorite, let countryCode = displayingGroup?.countryCode {
            return UIImage(named: "\(countryCode)-s") ?? super.iconImage
        } else if isProLocked {
            return UIImage(named: ImagesAsset.proCityImage)?
                .withRenderingMode(.alwaysTemplate)
        } else if isSpeedIconVisible {
            return UIImage(named: ImagesAsset.tenGig)?
                .withRenderingMode(.alwaysTemplate)
        }
        return super.iconImage
    }

    var isProLocked: Bool {
        guard let group = displayingGroup else { return false }
        return group.premiumOnly &&
        !(sessionManager.session?.isPremium ?? false)
    }

    override var hasProLocked: Bool { isProLocked && isFavorite }

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
    var nodeCellViewModel: NodeTableViewCellModelType? {
        didSet {
            baseNodeCellViewModel = nodeCellViewModel
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func updateUI() {
        super.updateUI()
        if nodeCellViewModel?.isFavorite ?? false {
            icon.image = nodeCellViewModel?.iconImage
        } else if nodeCellViewModel?.isProLocked ?? false {
            icon.setImageColor(color: .proStarColor)
        }
    }
}
