//
//  ServerDetailTableViewCell.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 19/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

protocol ServerListTableViewDelegate: AnyObject {
    func setSelectedServerAndGroup(server: ServerModel, group: GroupModel)
    func showUpgradeView()
    func showExpiredAccountView()
    func showOutOfDataPopUp()
    func reloadTable(cell: UITableViewCell)
}

protocol FavouriteListTableViewDelegate: AnyObject {
    func setSelectedFavourite(favourite: GroupModel)
    func showUpgradeView()
    func showExpiredAccountView()
    func showOutOfDataPopUp()
}

protocol StaticIPListTableViewDelegate: AnyObject {
    func setSelectedStaticIP(staticIP: StaticIPModel)
}

class ServerDetailTableViewCell: UITableViewCell {
    @IBOutlet var favButton: UIButton!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var proIcon: UIImageView!
    weak var delegate: ServerListTableViewDelegate?
    weak var favDelegate: FavouriteListTableViewDelegate?
    weak var staticIpDelegate: StaticIPListTableViewDelegate?

    @IBOutlet var latencyLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!

    @IBOutlet var connectButtonTrailing: NSLayoutConstraint!
    let latencyRepository = Assembler.resolve(LatencyRepository.self)
    lazy var localDB = Assembler.resolve(LocalDatabase.self)
    lazy var preferences = Assembler.resolve(Preferences.self)
    var displayingGroup: GroupModel?
    var displayingNodeServer: ServerModel?
    var favIDs: [String] = []
    let disposeBag = DisposeBag()
    let vpnManager = Assembler.resolve(VPNManager.self)
    var myPreferredFocusedView: UIView?

    override var preferredFocusedView: UIView? {
        return myPreferredFocusedView
    }

    lazy var sessionManager: SessionManaging = Assembler.resolve(SessionManaging.self)

    var displayingFavGroup: GroupModel? {
        didSet {
            updateUIForFavourite()
        }
    }

    var displayingStaticIP: StaticIPModel? {
        didSet {
            updetaUIForStaticIP()
        }
    }

    var isFavourited: Bool = false
    private var isbtnFirst = false
    private var isbtnSecond = false
    private var isDefault = false

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        switch true {
        case isbtnFirst:
            return [connectButton]
        case isbtnSecond:
            return [favButton]
        default:
            return [connectButton]
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        favButton.layer.cornerRadius = favButton.frame.size.width / 2
        favButton.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        favButton.layer.borderWidth = 2.0
        favButton.clipsToBounds = true
        favButton.accessibilityIdentifier = AccessibilityIdentifier.favouriteButton
        favButton.addTarget(self, action: #selector(favButtonTapped), for: .primaryActionTriggered)
        setFavButtonImage()

        connectButton.layer.cornerRadius = connectButton.frame.size.width / 2
        connectButton.layer.borderColor = UIColor.whiteWithOpacity(opacity: 0.24).cgColor
        connectButton.layer.borderWidth = 2.0
        connectButton.clipsToBounds = true
        connectButton.setBackgroundImage(UIImage(named: ImagesAsset.TvAsset.connectIcon), for: .normal)
        connectButton.setBackgroundImage(UIImage(named: ImagesAsset.TvAsset.connectIconFocused), for: .focused)
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .primaryActionTriggered)
        cityLabel.textColor = .whiteWithOpacity(opacity: 0.50)
        connectButton.accessibilityIdentifier = AccessibilityIdentifier.connectButton

        latencyLabel.font = .bold(size: 30)
        latencyLabel.textColor = .whiteWithOpacity(opacity: 0.50)
        proIcon.alpha = 0.50

        descriptionLabel.textColor = .white
        descriptionLabel.font = .text(size: 30)
        descriptionLabel.isHidden = true
        descriptionLabel.text = ""
        proIcon.isHidden = true
        if let premiumOnly = displayingGroup?.premiumOnly, let isUserPro = sessionManager.session?.isPremium {
            if premiumOnly && !isUserPro {
                proIcon.isHidden = false
            }
        }
    }

    func updateUIForFavourite() {
        connectButtonTrailing.constant = 0
        favButton.isHidden = false
        if let city = displayingFavGroup?.city, let nick = displayingFavGroup?.nick {
            let fullText = "\(city) \(nick)"
            let attributedString = NSMutableAttributedString(string: fullText)

            let firstRange = (fullText as NSString).range(of: city)
            attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)

            let secondRange = (fullText as NSString).range(of: nick)
            attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
            cityLabel.attributedText = attributedString
        }
        guard let pingIp = displayingFavGroup?.pingIp,
              let minTime = latencyRepository.getPingData(ip: pingIp)?.latency
        else {
            latencyLabel.text = "--"
            return
        }
        if minTime > 0 {
            latencyLabel.text = " \(minTime.description) MS"
        } else {
            latencyLabel.text = "--"
        }

        if let premiumOnly = displayingFavGroup?.premiumOnly, let isUserPro = sessionManager.session?.isPremium {
            if premiumOnly && !isUserPro {
                proIcon.isHidden = false
            } else {
                proIcon.isHidden = true
            }
        } else {
            proIcon.isHidden = true
        }
        preferences.observeFavouriteIds().subscribe(onNext: { favIDs in
            self.favIDs = favIDs
            if let id = self.displayingFavGroup?.id {
                self.isFavourited = favIDs.map { $0 }.contains("\(id)")
                self.setFavButtonImage()
            }
        }).disposed(by: disposeBag)
    }

    func updetaUIForStaticIP() {
        favButton.isHidden = true
        proIcon.isHidden = true
        connectButtonTrailing.constant = -125
        if let city = displayingStaticIP?.cityName, let nick = displayingStaticIP?.countryCode {
            let fullText = "\(city) \(nick)"
            let attributedString = NSMutableAttributedString(string: fullText)

            let firstRange = (fullText as NSString).range(of: city)
            attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)

            let secondRange = (fullText as NSString).range(of: nick)
            attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
            cityLabel.attributedText = attributedString
        }
        latencyLabel.font = .text(size: 30)
        if let bestNode = displayingStaticIP?.bestNode, bestNode.forceDisconnect == false {
            let bestNodeHostname = bestNode.ip1
            guard let minTime = latencyRepository.getPingData(ip: bestNodeHostname)?.latency else {
                latencyLabel.text = " "
                return
            }

            guard let staticIp = displayingStaticIP?.staticIP else {
                latencyLabel.text = minTime > 0 ? "\(minTime.description) MS" : ""
                return
            }
            latencyLabel.text = minTime > 0 ? "\(minTime.description) MS  \(staticIp)" : " \(staticIp)"
        }
    }

    func setFavButtonImage() {
        if isFavourited {
            favButton.setBackgroundImage(UIImage(named: ImagesAsset.TvAsset.removeFavIcon), for: .normal)
            favButton.setBackgroundImage(UIImage(named: ImagesAsset.TvAsset.removeFavIconFocused), for: .focused)
        } else {
            favButton.setBackgroundImage(UIImage(named: ImagesAsset.TvAsset.addFavIcon), for: .normal)
            favButton.setBackgroundImage(UIImage(named: ImagesAsset.TvAsset.addFavIconFocused), for: .focused)
        }
    }

    override func shouldUpdateFocus(in _: UIFocusUpdateContext) -> Bool {
        switch true {
        case isbtnFirst:
            cityLabel.textColor = .white
            latencyLabel.textColor = .white
            isbtnFirst = false
            return true
        case isbtnSecond:
            cityLabel.textColor = .white
            latencyLabel.textColor = .white
            isbtnSecond = false
            return true
        default:
            cityLabel.textColor = .whiteWithOpacity(opacity: 0.50)
            latencyLabel.textColor = .whiteWithOpacity(opacity: 0.50)
            return true
        }
    }

    override var canBecomeFocused: Bool {
        return false
    }

//    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
//        for press in presses {
//            if press.type == .leftArrow {
//               if UIScreen.main.focusedView == favButton {
//                    myPreferredFocusedView = connectButton
//                    self.setNeedsFocusUpdate()
//                    self.updateFocusIfNeeded()
//                }
//            }
//        }
//    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with _: UIFocusAnimationCoordinator) {
        if (context.previouslyFocusedView != nil) && (context.nextFocusedView != nil) {
            if context.nextFocusedView is ServerDetailTableViewCell && context.previouslyFocusedView != favButton {
                isbtnFirst = true
                setNeedsFocusUpdate()
            }
            if context.nextFocusedView == connectButton && context.previouslyFocusedView == connectButton {
                isbtnSecond = true
                setNeedsFocusUpdate()
            }
        }
        if connectButton.isFocused || favButton.isFocused {
            cityLabel.textColor = .white
            latencyLabel.textColor = .white
            proIcon.alpha = 1
            descriptionLabel.isHidden = false
            if connectButton.isFocused {
                descriptionLabel.text = TextsAsset.connect
                if let premiumOnly = displayingFavGroup?.premiumOnly, let isUserPro = sessionManager.session?.isPremium, favButton.isHidden == false {
                    if premiumOnly && !isUserPro {
                        descriptionLabel.text = TextsAsset.upgrade
                    }
                }
                if let premiumOnly = displayingGroup?.premiumOnly, let isUserPro = sessionManager.session?.isPremium, favButton.isHidden == false {
                    if premiumOnly && !isUserPro {
                        descriptionLabel.text = TextsAsset.upgrade
                    }
                }

            } else if favButton.isFocused {
                if isFavourited {
                    descriptionLabel.text = TextsAsset.TVAsset.removeFromFav
                } else {
                    descriptionLabel.text = TextsAsset.TVAsset.addToFav
                }
            }
        } else {
            cityLabel.textColor = .whiteWithOpacity(opacity: 0.50)
            latencyLabel.textColor = .whiteWithOpacity(opacity: 0.50)
            proIcon.alpha = 0.50
            descriptionLabel.isHidden = true
        }
    }

    func bindData(group: GroupModel) {
        displayingGroup = group
        let city = group.city
        let nick = group.nick
        let fullText = "\(city) \(nick)"
        let attributedString = NSMutableAttributedString(string: fullText)

        let firstRange = (fullText as NSString).range(of: city)
        attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)

        let secondRange = (fullText as NSString).range(of: nick)
        attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
        cityLabel.attributedText = attributedString

        guard let minTime = latencyRepository.getPingData(ip: group.pingIp)?.latency else {
            latencyLabel.text = " "
            return
        }
        if minTime > 0 {
            latencyLabel.text = " \(minTime.description) MS"
        } else {
            latencyLabel.text = "  "
        }
        preferences.observeFavouriteIds().subscribe(onNext: { favIDs in
            self.favIDs = favIDs
            self.isFavourited = favIDs.map { $0 }.contains("\(group.id)")
            self.setupUI()
        }).disposed(by: disposeBag)
    }

    @objc func favButtonTapped() {
        var group = displayingGroup
        if displayingFavGroup != nil {
            group = displayingFavGroup
        }
        guard let group = group else {
            return
        }
        if isFavourited {
            isFavourited = false
            setFavButtonImage()
            preferences.removeFavouriteId("\(group.id)")
            delegate?.reloadTable(cell: self)
        } else {
            isFavourited = true
            setFavButtonImage()
            preferences.addFavouriteId("\(group.id)")
            delegate?.reloadTable(cell: self)
        }
    }

    private func canAccessServer() -> Bool {
        if staticIpDelegate != nil {
            return true
        }
        if let bestNode = displayingGroup?.bestNode,
           let bestNodeHostname = displayingGroup?.bestNodeHostname,
           bestNode.forceDisconnect == false && isHostStillActive(hostname: bestNodeHostname),
           bestNodeHostname != "" {
            return true
        } else {
            return false
        }
    }

    @objc func connectButtonTapped() {
        if sessionManager.session?.status == 2 && staticIpDelegate == nil {
            let isPro = sessionManager.session?.isPremium ?? false
            guard let delegate = delegate else {
                if !isPro {
                    favDelegate?.showOutOfDataPopUp()
                }
                return
            }
            if !isPro {
                delegate.showOutOfDataPopUp()
            }
            return
        }

        if !favButton.isHidden && !proIcon.isHidden {
            delegate?.showUpgradeView()
            favDelegate?.showUpgradeView()
            return
        }
        if !canAccessServer() {
            AlertManager.shared.showSimpleAlert(viewController: delegate as? UIViewController,
                                                title: TextsAsset.TVAsset.locationMaintenanceTitle,
                                                message: TextsAsset.TVAsset.locationMaintenanceDescription,
                                                buttonText: TextsAsset.okay)
            return
        }
        if favButton.isHidden {
            guard let staticIp = displayingStaticIP else { return }
            staticIpDelegate?.setSelectedStaticIP(staticIP: staticIp)
        } else {
            guard let server = displayingNodeServer, let group = displayingGroup else {
                guard let favGroup = displayingFavGroup else { return }
                favDelegate?.setSelectedFavourite(favourite: favGroup)
                return
            }
            delegate?.setSelectedServerAndGroup(server: server, group: group)
        }
    }

    func isHostStillActive(hostname: String, isStaticIP _: Bool = false) -> Bool {
        guard let nodesList = localDB.getServers()?.flatMap({ $0.groups }).map({ $0.nodes }),
              let staticIPNodes = localDB.getStaticIPs()?.flatMap({ $0.nodes }) else { return false }
        for nodes in nodesList {
            for node in nodes {
                if node.hostname == hostname && node.forceDisconnect == false {
                    return true
                }
            }
        }
        for node in staticIPNodes {
            if node.hostname == hostname && node.forceDisconnect == false {
                return true
            }
        }
        return false
    }
}
