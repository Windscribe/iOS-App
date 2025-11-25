//
//  BaseNodeCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit
import Combine

protocol BaseNodeCellViewModelType: ServerCellModelType {
    var signalImage: UIImage? { get }
    var latencyValue: NSAttributedString { get }
    var nickName: String { get }
    var updateUISubject: PublishSubject<Void> { get }
    var groupId: String { get }
    var isActionVisible: Bool { get }
    var isSignalVisible: Bool { get }
    var isDisabled: Bool { get }

    func favoriteSelected()
}

class BaseNodeCellViewModel: BaseNodeCellViewModelType {
    let localDB = Assembler.resolve(LocalDatabase.self)
    let preferences = Assembler.resolve(Preferences.self)

    let updateUISubject = PublishSubject<Void>()
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private var locationLoad: Bool = DefaultValues.showServerHealth

    var showServerHealth: Bool { locationLoad }
    var favList: [Favourite] = []
    var isFavourited: Bool = false
    var minTime = -1

    var groupId: String { "" }

    var name: String { "" }

    var nickName: String { "" }

    var iconAspect: UIView.ContentMode { .scaleToFill }
    var iconImage: UIImage? {
        UIImage(named: ImagesAsset.locationIcon)?.withRenderingMode(.alwaysTemplate)
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

    var hasProLocked: Bool { false }

    var signalImage: UIImage? {
        if minTime < 0 { return UIImage(named: ImagesAsset.CellSignalBars.none) }
        switch getSignalLevel(minTime: minTime) {
        case 1:
            return UIImage(named: ImagesAsset.CellSignalBars.low)
        case 2:
            return UIImage(named: ImagesAsset.CellSignalBars.medium)
        case 3:
            return UIImage(named: ImagesAsset.CellSignalBars.full)
        default:
            return UIImage(named: ImagesAsset.CellSignalBars.full)
        }
    }

    var isActionVisible: Bool { true }

    var isSignalVisible: Bool { true }

    var isDisabled: Bool { false }

    var latencyValue: NSAttributedString {
        if minTime > 0 {
            let latencyText = "\(minTime.description)ms"
            let attributedString = NSMutableAttributedString(string: latencyText)

            if let msRange = latencyText.range(of: "ms") {
                let nsRange = NSRange(msRange, in: latencyText)
                attributedString.addAttribute(.font, value: UIFont.medium(size: 7), range: nsRange)
            }
            return attributedString
        } else {
            return NSAttributedString(string: "  --  ")
        }
    }

    init() {
        favList = localDB.getFavouriteList()
        localDB.getFavouriteListObservable().subscribe(onNext: { [weak self] favList in
            guard let self = self else { return }
            self.favList = favList
            let prevIsFavourited = self.isFavourited
            self.isFavourited = isNodeFavorited()
            if prevIsFavourited != self.isFavourited {
                self.updateUISubject.onNext(())
            }
        }).disposed(by: disposeBag)

        preferences.getShowServerHealth()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                self.locationLoad = enabled ?? DefaultValues.showServerHealth
                self.updateUISubject.onNext(())
            }
            .store(in: &cancellables)
    }

    func favoriteSelected() { }

    func isNodeFavorited() -> Bool {
        favList.filter { !$0.isInvalidated }
            .map({ $0.id }).contains(groupId)
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
    var infoStackView = UIStackView()
    var latencyLabel = UILabel()
    var signalBarsIcon = UIImageView()
    var latencyView = UIView()
    var disabledIcon = UIImageView()
    var disabledContainer = UIView()
    private var cancellables = Set<AnyCancellable>()

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

        disabledIcon.image = UIImage(named: ImagesAsset.locationDown)?.withRenderingMode(.alwaysTemplate)
        disabledContainer.addSubview(disabledIcon)
        iconsStackView.insertArrangedSubview(disabledContainer, at: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func bindViews(isDarkMode: CurrentValueSubject<Bool, Never>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                guard let self = self else { return }
                self.nickNameLabel.textColor = .from(.textColor, isDark)
                self.latencyLabel.textColor = .from(.textColor, isDark)
                self.signalBarsIcon.setImageColor(color: .from(.iconColor, isDark))
                self.icon.setImageColor(color: .from(.iconColor, isDark))
                self.disabledIcon.setImageColor(color: .from(.iconColor, isDark))
            }
            .store(in: &cancellables)
    }

    override func updateLayout() {
        super.updateLayout()

        favButton.translatesAutoresizingMaskIntoConstraints = false
        latencyLabel.translatesAutoresizingMaskIntoConstraints = false
        signalBarsIcon.translatesAutoresizingMaskIntoConstraints = false
        nickNameLabel.translatesAutoresizingMaskIntoConstraints = false
        latencyView.translatesAutoresizingMaskIntoConstraints = false
        disabledContainer.translatesAutoresizingMaskIntoConstraints = false
        disabledIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // nickNameLabel
            nickNameLabel.heightAnchor.constraint(equalToConstant: 20),

            // favButton
            favButton.centerYAnchor.constraint(equalTo: actionImage.centerYAnchor),
            favButton.centerXAnchor.constraint(equalTo: actionImage.centerXAnchor),
            favButton.heightAnchor.constraint(equalTo: actionImage.heightAnchor, constant: 8),
            favButton.widthAnchor.constraint(equalTo: actionImage.widthAnchor, constant: 8),

            // disabledContainer
            disabledContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            disabledContainer.heightAnchor.constraint(equalToConstant: 24),
            disabledContainer.widthAnchor.constraint(equalToConstant: 24),

            // disabledIcon
            disabledIcon.centerYAnchor.constraint(equalTo: disabledContainer.centerYAnchor),
            disabledIcon.centerXAnchor.constraint(equalTo: disabledContainer.centerXAnchor),
            disabledIcon.heightAnchor.constraint(equalToConstant: 16),
            disabledIcon.widthAnchor.constraint(equalToConstant: 14),

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
        favButton.isEnabled = true
        nickNameLabel.isEnabled = true
        nameLabel.isEnabled = true
        latencyLabel.attributedText = baseNodeCellViewModel?.latencyValue
        signalBarsIcon.image = baseNodeCellViewModel?.signalImage
        nickNameLabel.text = baseNodeCellViewModel?.nickName

        latencyView.isHidden = !(baseNodeCellViewModel?.isSignalVisible ?? false)
        disabledIcon.isHidden = !(baseNodeCellViewModel?.isDisabled ?? false)

        super.updateUI()
    }

    @objc func favButtonTapped() {
        baseNodeCellViewModel?.favoriteSelected()
    }
}
