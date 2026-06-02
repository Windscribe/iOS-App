//
//  NodeTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

protocol DatacenterTableViewCellModelType: BaseNodeCellViewModelType {
    var displayingDatacenter: DatacenterModel? { get }
    var isProLocked: Bool { get }
    var isSpeedIconVisible: Bool { get }
    var isFavoriteCell: Bool { get }
    var countryCode: String? { get }
    var showP2P: Bool { get }
    var delegate: DatacenterTableViewCellModelDelegate? { get set }

    func update(displayingDatacenter: DatacenterModel?,
                locationLoad: Bool,
                isSavedHasFav: Bool,
                hasAccess: Bool,
                isDarkMode: Bool,
                latency: Int,
                countryCode: String?)
}

protocol DatacenterTableViewCellModelDelegate: AnyObject {
    func saveAsFavorite(datacenterId: Int)
    func removeFavorite(datacenterId: Int)
}

class DatacenterTableViewCellModel: BaseNodeCellViewModel, DatacenterTableViewCellModelType {
    weak var delegate: DatacenterTableViewCellModelDelegate?

    var displayingDatacenter: DatacenterModel?
    var isFavoriteCell: Bool { return false }

    var hasAccess: Bool = false
    var countryCode: String?

    func update(displayingDatacenter: DatacenterModel?,
                locationLoad: Bool,
                isSavedHasFav: Bool,
                hasAccess: Bool,
                isDarkMode: Bool,
                latency: Int,
                countryCode: String?) {
        self.displayingDatacenter = displayingDatacenter
        self.locationLoad = locationLoad
        self.isSavedHasFav = isSavedHasFav
        self.hasAccess = hasAccess
        self.isDarkMode = isDarkMode
        self.latency = latency
    }

    override var isSignalVisible: Bool { !(isDisabled || displayingDatacenter?.servers.count == 0 || latency < 0) }
    override var isDisabled: Bool {
        guard let displayingDatacenter else { return true }
        let status = displayingDatacenter.getStatus(hasAccess: hasAccess)
        if status == .underMantainance { return true }
        return false
    }

    var isProLocked: Bool {
        guard let datacenter = displayingDatacenter else { return false }
        return datacenter.isPremiumOnly && !hasAccess
    }

    override var showP2P: Bool { displayingDatacenter?.p2p != 1 }

    override var serverNetLoad: CGFloat {
        CGFloat(self.displayingDatacenter?.netLoad ?? 0)
    }

    override var datacenterId: Int {
        displayingDatacenter?.id ?? 0
    }

    override var name: String {
        displayingDatacenter?.city ?? ""
    }

    override var nickName: String {
        displayingDatacenter?.nick ?? ""
    }

    override var iconSize: CGFloat {
        if isFavoriteCell { return 20.0 }
        if isProLocked { return super.iconSize }
        if isSpeedIconVisible { return 16.0 }
        return 20.0
    }

    override var iconImage: UIImage? {
        if isFavoriteCell, let countryCode = self.countryCode {
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

    override var hasProLocked: Bool { isProLocked && isFavoriteCell }

    var isSpeedIconVisible: Bool {
        displayingDatacenter?.linkSpeed == 10000
    }

    override func favoriteSelected() {
        if isSavedHasFav {
            delegate?.removeFavorite(datacenterId: self.datacenterId)
        } else {
            delegate?.saveAsFavorite(datacenterId: self.datacenterId)
        }
    }
}

class DatacenterTableViewCell: BaseNodeCell {
    var datacenterCellViewModel: DatacenterTableViewCellModelType? {
        didSet {
            baseNodeCellViewModel = datacenterCellViewModel
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func updateLayout() {
        super.updateLayout()

        NSLayoutConstraint.activate([
            // p2pIcon
            p2pIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            p2pIcon.heightAnchor.constraint(equalToConstant: 16),
            p2pIcon.widthAnchor.constraint(equalToConstant: 16)
        ])
    }

    override func updateUI() {
        super.updateUI()
        if datacenterCellViewModel?.isFavoriteCell ?? false {
            icon.image = datacenterCellViewModel?.iconImage
        } else if datacenterCellViewModel?.isProLocked ?? false {
            icon.setImageColor(color: .proStarColor)
        }
    }
}
