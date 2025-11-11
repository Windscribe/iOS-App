//
//  FavNodeTableViewCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Realm
import RealmSwift
import RxSwift
import Swinject
import UIKit

class FavNodeTableViewCellModel: NodeTableViewCellModel {
    var displayingFavGroup: FavouriteGroupModel?

    override var nickName: String {
        return  displayingFavGroup?.pinnedIp ?? "Random Ip"
    }

    init(displayingFavGroup: FavouriteGroupModel? = nil) {
        self.displayingFavGroup = displayingFavGroup
        super.init(displayingGroup: displayingFavGroup?.groupModel, isFavorite: true)
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

        nickNameLabel.font = UIFont.text(size: 12)
        nickNameLabel.layer.opacity = 0.6
    }
}
