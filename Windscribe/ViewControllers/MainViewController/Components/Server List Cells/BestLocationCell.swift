//
//  BestLocationCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class BestLocationCellModel: LocationCellModelType {
    var isDarkMode: Bool = false

    var displayingBestLocation: BestLocationModel?
    var locationLoad: Bool = DefaultValues.showServerNetLoad

    var name: String {
        TextsAsset.bestLocation
    }

    var iconAspect: UIView.ContentMode { .scaleAspectFill }
    var iconImage: UIImage? {
        guard let countryCode = displayingBestLocation?.countryCode else { return nil }
        return UIImage(named: "\(countryCode)-s")
    }

    var shouldTintIcon: Bool { false }

    var actionImage = UIImage(named: ImagesAsset.serverWhiteRightArrow)

    var iconSize: CGFloat = 20.0

    var actionSize: CGFloat = 16.0

    var actionRightOffset: CGFloat = 15.0

    var actionVisible: Bool = true

    var actionOpacity: Float = 0.4

    var hasProLocked: Bool = false

    var serverNetLoad: CGFloat {
        CGFloat(self.displayingBestLocation?.netLoad ?? 0)
    }

    func update(bestLocationModel: BestLocationModel?,
                locationLoad: Bool,
                isDarkMode: Bool) {
        self.displayingBestLocation = bestLocationModel
        self.locationLoad = locationLoad
        self.isDarkMode = isDarkMode
    }

    func nameColor(for isDarkMode: Bool) -> UIColor {
        .from( .infoColor, isDarkMode)
    }
}

class BestLocationCell: LocationListCell {
    var bestCellViewModel: BestLocationCellModel? {
        didSet {
            viewModel = bestCellViewModel
            refreshUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = bestCellViewModel
        updateLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
