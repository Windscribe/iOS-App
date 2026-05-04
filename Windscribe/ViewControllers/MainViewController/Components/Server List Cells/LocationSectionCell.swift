//
//  LocationSectionCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

protocol LocationSectionCellModelType: LocationCellModelType {
    var isExpanded: Bool { get }
    var displayingLocation: LocationModel? { get }
    func setIsExpanded(_ value: Bool)

    func update(locationModel: LocationModel?,
                locationLoad: Bool,
                isPremium: Bool,
                isDarkMode: Bool,
                alcList: [String])
}

class LocationSectionCellModel: LocationSectionCellModelType {
    var isDarkMode: Bool = false
    var isExpanded: Bool = false
    var isPremium: Bool = false
    var locationLoad: Bool = DefaultValues.showServerNetLoad
    var alcList: [String] = []

    var displayingLocation: LocationModel?

    var name: String {
        displayingLocation?.name ?? ""
    }

    var iconAspect: UIView.ContentMode { .scaleAspectFill }
    var iconImage: UIImage? {
        guard let countryCode = displayingLocation?.countryCode else { return nil }
        return UIImage(named: "\(countryCode)-s")
    }

    var shouldTintIcon: Bool { false }

    var actionImage: UIImage? {
        UIImage(named: !isExpanded ? ImagesAsset.cellExpand : ImagesAsset.cellCollapse)?
            .withRenderingMode(.alwaysTemplate)
    }

    var iconSize: CGFloat = 20.0

    var actionSize: CGFloat = 20.0

    var actionRightOffset: CGFloat = 16.0

    var actionVisible: Bool = true

    var actionOpacity: Float {
        isExpanded ? 1.0 : 0.4
    }

    var nameOpacity: Float { 1.0 }

    var serverNetLoad: CGFloat {
        CGFloat(self.displayingLocation?.getServerNetLoad() ?? 0)
    }

    var hasProLocked: Bool {
        guard let location = displayingLocation else { return false }
        let hasAlcAccess = alcList.contains(location.shortName)
        return location.isPremiumOnly && !isPremium && !hasAlcAccess
    }

    func setIsExpanded(_ value: Bool) {
        isExpanded = value
    }

    func nameColor(for isDarkMode: Bool) -> UIColor {
        isExpanded ?
            .from( .textColor, isDarkMode) :
            .from( .infoColor, isDarkMode)
    }

    func update(locationModel: LocationModel?,
                locationLoad: Bool,
                isPremium: Bool,
                isDarkMode: Bool,
                alcList: [String]) {
        self.displayingLocation = locationModel
        self.locationLoad = locationLoad
        self.isPremium = isPremium
        self.isDarkMode = isDarkMode
        self.alcList = alcList
    }
}

class LocationSectionCell: LocationListCell {

    var locationCellViewModel: LocationSectionCellModel? {
        didSet {
            viewModel = locationCellViewModel
            refreshUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = locationCellViewModel
        refreshUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setCollapsed(collapsed: Bool, completion _: @escaping () -> Void = {}) {
        locationCellViewModel?.setIsExpanded(!collapsed)
        updateUI()
    }

    override func updateUI() {
        super.updateUI()
        guard let locationCellViewModel = locationCellViewModel else { return }
    }

    private func animateExpansion(completion: @escaping () -> Void = {}) {
        guard let locationCellViewModel = locationCellViewModel else { return }
        let isDarkMode = locationCellViewModel.isDarkMode
        UIView.animate(withDuration: 0.15, animations: {
            self.actionImage.layer.opacity = locationCellViewModel.actionOpacity
            self.nameLabel.textColor = locationCellViewModel.nameColor(for: isDarkMode)
        }, completion: { _ in
            completion()
        })
        UIView.transition(with: actionImage,
                          duration: 0.15,
                          options: .transitionCrossDissolve,
                          animations: { self.actionImage.image = locationCellViewModel.actionImage },
                          completion: nil)
    }

    func expand(completion: @escaping () -> Void = {}) {
        guard let locationCellViewModel = locationCellViewModel else { return }
        if !locationCellViewModel.isExpanded {
            locationCellViewModel.setIsExpanded(true)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }

    func collapse(completion: @escaping () -> Void = {}) {
        guard let locationCellViewModel = locationCellViewModel else { return }
        if locationCellViewModel.isExpanded {
            locationCellViewModel.setIsExpanded(false)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }
}
