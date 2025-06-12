//
//  ServerSectionCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

protocol ServerSectionCellModelType: ServerCellModelType {
    var isExpanded: Bool { get }
    var isP2pHidden: Bool { get }
    var displayingServer: ServerModel? { get }
    func setIsExpanded(_ value: Bool)
    func setDisplayingServer(_ value: ServerModel?)
}

class ServerSectionCellModel: ServerSectionCellModelType {
    let preferences = Assembler.resolve(Preferences.self)
    var sessionManager = Assembler.resolve(SessionManaging.self)
    let disposeBag = DisposeBag()
    let updateUISubject = PublishSubject<Void>()

    var isExpanded: Bool = false
    var showServerHealth: Bool = DefaultValues.showServerHealth

    var displayingServer: ServerModel?

    var name: String {
        displayingServer?.name ?? ""
    }

    var clipIcon: Bool { true }
    var iconAspect: UIView.ContentMode { .scaleAspectFill }
    var iconImage: UIImage? {
        guard let countryCode = displayingServer?.countryCode else { return nil }
        return UIImage(named: "\(countryCode)-s")
    }

    var shouldTintIcon: Bool { false }

    var actionImage: UIImage? {
        UIImage(named: !isExpanded ? ImagesAsset.cellExpand : ImagesAsset.cellCollapse)
    }

    var iconSize: CGFloat = 20.0

    var actionSize: CGFloat = 16.0

    var actionRightOffset: CGFloat = 24.0

    var actionOpacity: Float {
        isExpanded ? 1.0 : 0.4
    }

    var nameOpacity: Float {
        isExpanded ? 1.0 : 0.7
    }

    var serverHealth: CGFloat {
        CGFloat(self.displayingServer?.getServerHealth() ?? 0)
    }

    var isP2pHidden: Bool {
        displayingServer?.p2p ?? false
    }

    var hasProLocked: Bool {
        let hasPro = displayingServer?.groups.first {
            $0.premiumOnly
        }
        return (hasPro?.premiumOnly ?? false) &&
        !(sessionManager.session?.isPremium ?? false)
    }

    init() {
        preferences.getShowServerHealth().subscribe(onNext: { [weak self] enabled in
            guard let self = self else { return }
            self.showServerHealth = enabled ?? DefaultValues.showServerHealth
            self.updateUISubject.onNext(())
        }).disposed(by: disposeBag)
    }

    func setIsExpanded(_ value: Bool) {
        isExpanded = value
    }

    func setDisplayingServer(_ value: ServerModel?) {
        displayingServer = value
    }

    func nameColor(for isDarkMode: Bool) -> UIColor {
        isExpanded ?
            .from( .textColor, isDarkMode) :
            .from( .infoColor, isDarkMode)
    }
}

class ServerSectionCell: ServerListCell {
    var p2pIcon = UIImageView()
    var proIcon = UIImageView()

    var serverCellViewModel: ServerSectionCellModel? {
        didSet {
            viewModel = serverCellViewModel
            updateLayout()
            updateUI()
            serverCellViewModel?.updateUISubject.subscribe { [weak self] _ in
                self?.updateUI()
            }.disposed(by: disposeBag)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewModel = serverCellViewModel

        p2pIcon.image = UIImage(named: ImagesAsset.p2p)
        p2pIcon.setImageColor(color: .white)
        p2pIcon.layer.opacity = 0.7
        contentView.addSubview(p2pIcon)

        proIcon.image = UIImage(named: ImagesAsset.proMiniImage)
        proIcon.setImageColor(color: .proStarColor)
        contentView.addSubview(proIcon)

        updateUI()
        updateLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func updateServerModel(_ value: ServerModel?) {
        serverCellViewModel?.setDisplayingServer(value)
        updateUI()
    }

    func setCollapsed(collapsed: Bool, completion _: @escaping () -> Void = {}) {
        serverCellViewModel?.setIsExpanded(!collapsed)
        updateUI()
    }

    override func updateUI() {
        super.updateUI()
        guard let serverCellViewModel = serverCellViewModel else { return }
        p2pIcon.isHidden = serverCellViewModel.isP2pHidden
        proIcon.isHidden = !serverCellViewModel.hasProLocked
    }

    override func updateLayout() {
        super.updateLayout()

        p2pIcon.translatesAutoresizingMaskIntoConstraints = false
        proIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // p2pIcon
            p2pIcon.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            p2pIcon.rightAnchor.constraint(equalTo: actionImage.leftAnchor, constant: -14),
            p2pIcon.heightAnchor.constraint(equalToConstant: 16),
            p2pIcon.widthAnchor.constraint(equalToConstant: 16),

                // proIcon
            proIcon.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            proIcon.leftAnchor.constraint(equalTo: leftAnchor, constant: 11),
            proIcon.heightAnchor.constraint(equalToConstant: 16),
            proIcon.widthAnchor.constraint(equalToConstant: 16)
        ])
    }

    override func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        super.bindViews(isDarkMode: isDarkMode)
        isDarkMode.subscribe(onNext: { isDarkMode in
            self.p2pIcon.setImageColor(color: .from(.iconColor, isDarkMode))
            let proImageName = isDarkMode ? ImagesAsset.proMiniImage : ImagesAsset.proMiniLightImage
            self.proIcon.image = UIImage(named: proImageName)
        }).disposed(by: disposeBag)
    }

    private func animateExpansion(completion: @escaping () -> Void = {}) {
        guard let serverCellViewModel = serverCellViewModel else { return }
        UIView.animate(withDuration: 0.35, animations: {
            self.nameLabel.layer.opacity = serverCellViewModel.nameOpacity
            self.actionImage.layer.opacity = serverCellViewModel.actionOpacity
        }, completion: { _ in
            completion()
        })
        UIView.transition(with: actionImage,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: { self.actionImage.image = serverCellViewModel.actionImage },
                          completion: nil)
    }

    func expand(completion: @escaping () -> Void = {}) {
        guard let serverCellViewModel = serverCellViewModel else { return }
        if !serverCellViewModel.isExpanded {
            serverCellViewModel.setIsExpanded(true)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }

    func collapse(completion: @escaping () -> Void = {}) {
        guard let serverCellViewModel = serverCellViewModel else { return }
        if serverCellViewModel.isExpanded {
            serverCellViewModel.setIsExpanded(false)
            animateExpansion(completion: completion)
        } else {
            completion()
        }
    }
}
