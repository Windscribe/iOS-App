//
//  BaseNodeCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Realm
import RealmSwift
import RxSwift
import Swinject
import UIKit

protocol BaseNodeCellViewModelType: ServerCellModelType {
    var signalImage: UIImage? { get }
    var latencyValue: String { get }
    var nickName: String { get }
    var updateUISubject: PublishSubject<Void> { get }
    var groupId: String { get }
    var isActionVisible: Bool { get }
    var isSignalVisible: Bool { get }

    func favoriteSelected()
}

class BaseNodeCellViewModel: BaseNodeCellViewModelType {
    let localDB = Assembler.resolve(LocalDatabase.self)
    let preferences = Assembler.resolve(Preferences.self)

    let updateUISubject = PublishSubject<Void>()
    let disposeBag = DisposeBag()

    private var locationLoad: Bool = DefaultValues.showServerHealth

    var showServerHealth: Bool { locationLoad }
    var favNodes: [FavNode] = []
    var isFavourited: Bool = false
    var minTime = -1

    var groupId: String { "" }

    var name: String { "" }

    var nickName: String { "" }

    var iconAspect: UIView.ContentMode { .scaleToFill }
    var iconImage: UIImage? {
        UIImage(named: ImagesAsset.cityImage)?.withRenderingMode(.alwaysTemplate)
    }

    var shouldTintIcon: Bool { true }

    var actionImage: UIImage? {
        UIImage(named: isFavourited ? ImagesAsset.favFull : ImagesAsset.favEmpty)
    }

    var iconSize: CGFloat { 24.0 }

    var actionSize: CGFloat { 20.0 }

    var actionRightOffset: CGFloat { 14.0 }

    var actionVisible: Bool { true }

    var actionOpacity: Float {
        0.4
    }

    var serverHealth: CGFloat { 0.0 }

    var signalImage: UIImage? {
        switch getSignalLevel(minTime: minTime) {
        case 1:
            UIImage(named: ImagesAsset.CellSignalBars.low)
        case 2:
            UIImage(named: ImagesAsset.CellSignalBars.medium)
        case 3:
            UIImage(named: ImagesAsset.CellSignalBars.full)
        default:
            UIImage(named: ImagesAsset.CellSignalBars.full)
        }
    }

    var isActionVisible: Bool { true }

    var isSignalVisible: Bool { true }

    var latencyValue: String {
        minTime > 0 ? "  \(minTime.description)  " : "  --  "
    }

    init() {
        favNodes = localDB.getFavNodeSync()
        localDB.getFavNode().subscribe(onNext: { [weak self] favNodes in
            guard let self = self else { return }
            self.favNodes = favNodes
            let prevIsFavourited = self.isFavourited
            self.isFavourited = isNodeFavorited()
            if prevIsFavourited != self.isFavourited {
                self.updateUISubject.onNext(())
            }
        }).disposed(by: disposeBag)

        preferences.getShowServerHealth().subscribe(onNext: { [weak self] enabled in
            guard let self = self else { return }
            self.locationLoad = enabled ?? DefaultValues.showServerHealth
            self.updateUISubject.onNext(())
        }).disposed(by: disposeBag)
    }

    func favoriteSelected() { }

    func isNodeFavorited() -> Bool {
        favNodes
            .filter{ !$0.isInvalidated }
            .map({ $0.groupId }).contains(groupId)
    }

    private func getSignalLevel(minTime: Int) -> Int {
        var signalLevel = 0
        if minTime <= 100 {
            signalLevel = 3
        } else if minTime <= 250 {
            signalLevel = 2
        } else {
            signalLevel = 1
        }
        return signalLevel
    }

    func nameColor(for isDarkMode: Bool) -> UIColor {
        .from( .textColor, isDarkMode)
    }
}

class BaseNodeCell: ServerListCell {
    var favButton = ImageButton()
    var nickNameLabel = UILabel()
    var latencyLabel = UILabel()
    var signalBarsIcon = UIImageView()
    var latencyView = UIView()

    var baseNodeCellViewModel: BaseNodeCellViewModelType? {
        didSet {
            viewModel = baseNodeCellViewModel
            updateLayout()
            updateUI()
            baseNodeCellViewModel?.updateUISubject.subscribe { [weak self] _ in
                self?.updateUI()
            }.disposed(by: disposeBag)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        favButton.addTarget(self, action: #selector(favButtonTapped), for: .touchUpInside)
        favButton.layer.opacity = 0.4
        contentView.addSubview(favButton)

        nickNameLabel.font = UIFont.text(size: 16)
        nickNameLabel.layer.opacity = 1
        nameInfoStackView.addArrangedSubview(nickNameLabel)

        latencyLabel.font = UIFont.medium(size: 9)
        latencyLabel.layer.opacity = 0.7
        latencyView.addSubview(latencyLabel)

        signalBarsIcon.image = UIImage(named: ImagesAsset.CellSignalBars.full)
        latencyView.addSubview(signalBarsIcon)

        iconsStackView.insertArrangedSubview(latencyView, at: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode.subscribe(onNext: { isDarkMode in
            self.nickNameLabel.textColor = .from(.textColor, isDarkMode)
            self.latencyLabel.textColor = .from(.textColor, isDarkMode)
            self.signalBarsIcon.setImageColor(color: .from(.iconColor, isDarkMode))
            self.icon.setImageColor(color: .from(.iconColor, isDarkMode))
        }).disposed(by: disposeBag)
    }

    override func updateLayout() {
        super.updateLayout()

        favButton.translatesAutoresizingMaskIntoConstraints = false
        latencyLabel.translatesAutoresizingMaskIntoConstraints = false
        signalBarsIcon.translatesAutoresizingMaskIntoConstraints = false
        nickNameLabel.translatesAutoresizingMaskIntoConstraints = false
        latencyView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // nickNameLabel
            nickNameLabel.heightAnchor.constraint(equalToConstant: 20),

            // favButton
            favButton.centerYAnchor.constraint(equalTo: actionImage.centerYAnchor),
            favButton.centerXAnchor.constraint(equalTo: actionImage.centerXAnchor),
            favButton.heightAnchor.constraint(equalTo: actionImage.heightAnchor, constant: 8),
            favButton.widthAnchor.constraint(equalTo: actionImage.widthAnchor, constant: 8),

            // latencyView
            latencyView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            latencyView.heightAnchor.constraint(equalToConstant: 24),
            latencyView.widthAnchor.constraint(equalToConstant: 24),

            // latencyLabel
            signalBarsIcon.centerYAnchor.constraint(equalTo: latencyView.centerYAnchor, constant: -6),
            signalBarsIcon.centerXAnchor.constraint(equalTo: latencyView.centerXAnchor),
            signalBarsIcon.heightAnchor.constraint(equalToConstant: 11),
            signalBarsIcon.widthAnchor.constraint(equalToConstant: 11),

            // latencyLabel
            latencyLabel.centerYAnchor.constraint(equalTo: latencyView.centerYAnchor, constant: 6),
            latencyLabel.centerXAnchor.constraint(equalTo: latencyView.centerXAnchor),
            latencyLabel.heightAnchor.constraint(equalToConstant: 12)

        ])
    }

    override func updateUI() {
        latencyLabel.text = ""
        favButton.isEnabled = true
        nickNameLabel.isEnabled = true
        nameLabel.isEnabled = true
        latencyLabel.text = baseNodeCellViewModel?.latencyValue
        signalBarsIcon.image = baseNodeCellViewModel?.signalImage
        nickNameLabel.text = baseNodeCellViewModel?.nickName

        latencyLabel.isHidden = !(baseNodeCellViewModel?.isSignalVisible ?? false)
        signalBarsIcon.isHidden = !(baseNodeCellViewModel?.isSignalVisible ?? false)

        super.updateUI()
    }

    @objc func favButtonTapped() {
        baseNodeCellViewModel?.favoriteSelected()
    }
}
