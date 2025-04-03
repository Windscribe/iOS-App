//
//  BestLocationCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class BestLocationCellModel: ServerCellModelType {
    var preferences = Assembler.resolve(Preferences.self)
    var displayingBestLocation: BestLocationModel?

    var name: String {
        displayingBestLocation?.cityName ?? ""
    }

    var iconImage: UIImage? {
        guard let countryCode = displayingBestLocation?.countryCode else { return nil }
        return UIImage(named: "\(countryCode)-s")
    }

    var actionImage = UIImage(named: ImagesAsset.serverWhiteRightArrow)

    var iconSize: CGFloat = 20.0

    var actionSize: CGFloat = 16.0

    var actionRightOffset: CGFloat = 24.0

    var actionOpacity: Float = 0.4

    var nameOpacity: Float = 0.8

    var serverHealth: CGFloat {
        CGFloat(self.displayingBestLocation?.health ?? 0)
    }
}

class BestLocationCell: ServerListCell {

    let bestCellViewModel = BestLocationCellModel()

    lazy var languageManager = Assembler.resolve(LanguageManagerV2.self)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = bestCellViewModel
        updateLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateBestLocation(_ value: BestLocationModel?) {
        bestCellViewModel.displayingBestLocation = value
    }

    override func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        super.bindViews(isDarkMode: isDarkMode)
        languageManager.activelanguage.subscribe { _ in
            self.updateUI()
        }.disposed(by: disposeBag)
    }
}
