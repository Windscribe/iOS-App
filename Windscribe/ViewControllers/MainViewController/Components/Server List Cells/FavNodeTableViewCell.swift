//
//  FavNodeTableViewCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class FavNodeTableViewCellModel: NodeTableViewCellModel {
    var displayingFavGroup: FavouriteGroupModel?

    var pinnedIpText: String {
        return displayingFavGroup?.pinnedIp ?? TextsAsset.Favorites.randomIP
    }

    override var isFavoriteCell: Bool { return true }

    override var name: String {
        // Show full name with nickname: "New York Empire" instead of just "New York"
        let cityName = displayingGroup?.city ?? ""
        let nickname = displayingGroup?.nick ?? ""
        if !nickname.isEmpty {
            return "\(cityName) \(nickname)"
        }
        return cityName
    }

    func update(displayingFavGroup: FavouriteGroupModel?,
                locationLoad: Bool,
                isSavedHasFav: Bool,
                isUserPro: Bool,
                isPremium: Bool,
                isDarkMode: Bool,
                latency: Int) {
        self.displayingFavGroup = displayingFavGroup
        self.displayingGroup = displayingFavGroup?.groupModel
        self.locationLoad = locationLoad
        self.isSavedHasFav = isSavedHasFav
        self.isUserPro = isUserPro
        self.isPremium = isPremium
        self.isDarkMode = isDarkMode
        self.latency = latency
    }
}

class FavNodeTableViewCell: BaseNodeCell {
    var favNodeCellViewModel: FavNodeTableViewCellModel? {
        didSet {
            baseNodeCellViewModel = favNodeCellViewModel
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
        icon.image = favNodeCellViewModel?.iconImage
        nameInfoStackView.axis = .vertical
        nameInfoStackView.spacing = 0

        // Show pinned IP as subtitle instead of nickname
        nickNameLabel.text = favNodeCellViewModel?.pinnedIpText
        nickNameLabel.font = UIFont.text(size: 12)
        nickNameLabel.layer.opacity = 0.6
    }
}
