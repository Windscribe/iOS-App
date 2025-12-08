//
//  NodeTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

protocol NodeTableViewCellModelType: BaseNodeCellViewModelType {
    var displayingGroup: GroupModel? { get }
    var isProLocked: Bool { get }
    var isSpeedIconVisible: Bool { get }
    var isFavoriteCell: Bool { get }
    var delegate: NodeTableViewCellModelDelegate? { get set }

    func update(displayingGroup: GroupModel?,
                locationLoad: Bool,
                isSavedHasFav: Bool,
                isUserPro: Bool,
                isPremium: Bool,
                isDarkMode: Bool,
                latency: Int)
}

protocol NodeTableViewCellModelDelegate: AnyObject {
    func saveAsFavorite(groupId: String)
    func removeFavorite(groupId: String)
}

class NodeTableViewCellModel: BaseNodeCellViewModel, NodeTableViewCellModelType {
    weak var delegate: NodeTableViewCellModelDelegate?

    var displayingGroup: GroupModel?
    var isFavoriteCell: Bool { return false }

    var isPremium: Bool = false
    var isUserPro: Bool = false

    func update(displayingGroup: GroupModel?,
                locationLoad: Bool,
                isSavedHasFav: Bool,
                isUserPro: Bool,
                isPremium: Bool,
                isDarkMode: Bool,
                latency: Int) {
        self.displayingGroup = displayingGroup
        self.locationLoad = locationLoad
        self.isSavedHasFav = isSavedHasFav
        self.isUserPro = isUserPro
        self.isPremium = isPremium
        self.isDarkMode = isDarkMode
        self.latency = latency
    }

    override var isSignalVisible: Bool { !isDisabled }
    override var isDisabled: Bool {
        guard let displayingGroup else { return true }
        // If there is no best node means user cannot connect to this location
        if displayingGroup.bestNode == nil {
            // this can be because the user is free and the location is pro
            // and in that case we should just show it as pro location - it is not disabled
            if !isUserPro && displayingGroup.premiumOnly { return false }
            // if the locations has a node that is not best node check forceDisconnect
            // if it forces to disconnect then the location is disabled
            if let node = displayingGroup.nodes.first {
                return node.forceDisconnect
            }
            // this locations is disabled as all the reasons have been exausted
            return true
        }
        return false
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
        if isFavoriteCell { return 20.0 }
        if isProLocked { return super.iconSize }
        if isSpeedIconVisible { return 16.0 }
        return 20.0
    }

    override var iconImage: UIImage? {
        if isFavoriteCell, let countryCode = displayingGroup?.countryCode {
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
        return group.premiumOnly && !isPremium
    }

    override var hasProLocked: Bool { isProLocked && isFavoriteCell }

    var isSpeedIconVisible: Bool {
        displayingGroup?.linkSpeed == "10000"
    }

    override func favoriteSelected() {
        if isSavedHasFav {
            delegate?.removeFavorite(groupId: self.groupId)
        } else {
            delegate?.saveAsFavorite(groupId: self.groupId)
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
        if nodeCellViewModel?.isFavoriteCell ?? false {
            icon.image = nodeCellViewModel?.iconImage
        } else if nodeCellViewModel?.isProLocked ?? false {
            icon.setImageColor(color: .proStarColor)
        }
    }
}
