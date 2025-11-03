//
//  BestLocationCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Combine
import RxSwift
import Swinject
import UIKit

class BestLocationCellModel: ServerCellModelType {
    let preferences = Assembler.resolve(Preferences.self)
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    let updateUISubject = PublishSubject<Void>()

    var displayingBestLocation: BestLocationModel?
    var showServerHealth: Bool = DefaultValues.showServerHealth

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

    var serverHealth: CGFloat {
        CGFloat(self.displayingBestLocation?.health ?? 0)
    }

    init() {
        preferences.getShowServerHealth()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                self.showServerHealth = enabled ?? DefaultValues.showServerHealth
                self.updateUISubject.onNext(())
            }
            .store(in: &cancellables)
    }

    func nameColor(for isDarkMode: Bool) -> UIColor {
        .from( .infoColor, isDarkMode)
    }
}

class BestLocationCell: ServerListCell {
    var bestCellViewModel: BestLocationCellModel? {
        didSet {
            viewModel = bestCellViewModel
            updateLayout()
            updateUI()
            bestCellViewModel?.updateUISubject.subscribe { [weak self] _ in
                self?.updateUI()
            }.disposed(by: disposeBag)
        }
    }

    lazy var languageManager = Assembler.resolve(LanguageManager.self)
    private var cancellables = Set<AnyCancellable>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = bestCellViewModel
        updateLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateBestLocation(_ value: BestLocationModel?) {
        bestCellViewModel?.displayingBestLocation = value
    }

    override func bindViews(isDarkMode: CurrentValueSubject<Bool, Never>) {
        super.bindViews(isDarkMode: isDarkMode)
        languageManager.activelanguage.sink { _ in
            self.updateUI()
        }.store(in: &cancellables)
    }
}
