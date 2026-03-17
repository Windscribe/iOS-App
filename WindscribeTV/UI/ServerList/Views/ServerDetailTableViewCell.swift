//
//  ServerDetailTableViewCell.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 19/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Swinject
import UIKit

protocol LocationsListTableViewDelegate: AnyObject {
    func setSelectedLocationAndDatacenter(location: LocationModel, datacenter: DatacenterModel)
    func showUpgradeView()
    func showExpiredAccountView()
    func showOutOfDataPopUp()
    func reloadTable(cell: UITableViewCell)
}

protocol FavouriteListTableViewDelegate: AnyObject {
    func setSelectedFavourite(favourite: DatacenterModel)
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
    weak var delegate: LocationsListTableViewDelegate?
    weak var favDelegate: FavouriteListTableViewDelegate?
    weak var staticIpDelegate: StaticIPListTableViewDelegate?

    @IBOutlet var latencyLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!

    @IBOutlet var connectButtonTrailing: NSLayoutConstraint!
    let latencyRepository = Assembler.resolve(LatencyRepository.self)
    lazy var preferences = Assembler.resolve(Preferences.self)
    lazy var locationListRepository = Assembler.resolve(LocationListRepository.self)
    lazy var userSessionRepository: UserSessionRepository = Assembler.resolve(UserSessionRepository.self)
    lazy var staticIpRepository = Assembler.resolve(StaticIpRepository.self)
    lazy var alertManager = Assembler.resolve(AlertManager.self)

    var displayingDatacenter: DatacenterModel?
    var displayingNodeServer: LocationModel?
    var favIDs: [String] = []
    private var cancellables = Set<AnyCancellable>()
    let vpnManager = Assembler.resolve(VPNManager.self)
    var myPreferredFocusedView: UIView?

    override var preferredFocusedView: UIView? {
        return myPreferredFocusedView
    }

    var displayingFavDatacenter: DatacenterModel? {
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
        if let premiumOnly = displayingDatacenter?.isPremiumOnly, let isUserPro = userSessionRepository.sessionModel?.isPremium {
            if premiumOnly && !isUserPro {
                proIcon.isHidden = false
            }
        }
    }

    func updateUIForFavourite() {
        connectButtonTrailing.constant = 0
        favButton.isHidden = false
        if let city = displayingFavDatacenter?.city, let nick = displayingFavDatacenter?.nick {
            let fullText = "\(city) \(nick)"
            let attributedString = NSMutableAttributedString(string: fullText)

            let firstRange = (fullText as NSString).range(of: city)
            attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)

            let secondRange = (fullText as NSString).range(of: nick)
            attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
            cityLabel.attributedText = attributedString
        }
        guard let pingIp = displayingFavDatacenter?.pingServer?.ip,
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

        if let premiumOnly = displayingFavDatacenter?.isPremiumOnly, let isUserPro = userSessionRepository.sessionModel?.isPremium {
            if premiumOnly && !isUserPro {
                proIcon.isHidden = false
            } else {
                proIcon.isHidden = true
            }
        } else {
            proIcon.isHidden = true
        }
        preferences.observeFavouriteIds().sink { favIDs in
            self.favIDs = favIDs
            if let id = self.displayingFavDatacenter?.id {
                self.isFavourited = favIDs.map { $0 }.contains("\(id)")
                self.setFavButtonImage()
            }
        }.store(in: &cancellables)
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
                if let premiumOnly = displayingFavDatacenter?.isPremiumOnly,
                   let isUserPro = userSessionRepository.sessionModel?.isPremium,
                   favButton.isHidden == false {
                    if premiumOnly && !isUserPro {
                        descriptionLabel.text = TextsAsset.upgrade
                    }
                }
                if let premiumOnly = displayingDatacenter?.isPremiumOnly,
                   let isUserPro = userSessionRepository.sessionModel?.isPremium,
                   favButton.isHidden == false {
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

    func bindData(datacenter: DatacenterModel) {
        displayingDatacenter = datacenter
        let city = datacenter.city
        let nick = datacenter.nick
        let fullText = "\(city) \(nick)"
        let attributedString = NSMutableAttributedString(string: fullText)

        let firstRange = (fullText as NSString).range(of: city)
        attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)

        let secondRange = (fullText as NSString).range(of: nick)
        attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
        cityLabel.attributedText = attributedString

        guard let pintIP = datacenter.pingServer?.ip, let minTime = latencyRepository.getPingData(ip: pintIP)?.latency else {
            latencyLabel.text = " "
            return
        }
        if minTime > 0 {
            latencyLabel.text = " \(minTime.description) MS"
        } else {
            latencyLabel.text = "  "
        }
        preferences.observeFavouriteIds().sink { favIDs in
            self.favIDs = favIDs
            self.isFavourited = favIDs.map { $0 }.contains("\(datacenter.id)")
            self.setupUI()
        }.store(in: &cancellables)
    }

    @objc func favButtonTapped() {
        var datacenter = displayingDatacenter
        if displayingFavDatacenter != nil {
            datacenter = displayingFavDatacenter
        }
        guard let datacenter = datacenter else {
            return
        }
        if isFavourited {
            isFavourited = false
            setFavButtonImage()
            preferences.removeFavouriteId("\(datacenter.id)")
            delegate?.reloadTable(cell: self)
        } else {
            isFavourited = true
            setFavButtonImage()
            preferences.addFavouriteId("\(datacenter.id)")
            delegate?.reloadTable(cell: self)
        }
    }

    private func canAccessServer() -> Bool {
        if staticIpDelegate != nil {
            return true
        }

        // Check whichever datacenter is set (regular location list or favorites)
        let datacenter = displayingDatacenter ?? displayingFavDatacenter
        if datacenter?.servers.isEmpty == false {
            return true
        }

        return false
    }

    @objc func connectButtonTapped() {
        if userSessionRepository.sessionModel?.status == 2 && staticIpDelegate == nil {
            let isPro = userSessionRepository.sessionModel?.isPremium ?? false
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
            alertManager.showSimpleAlert(viewController: delegate as? UIViewController,
                                         title: TextsAsset.TVAsset.locationMaintenanceTitle,
                                         message: TextsAsset.TVAsset.locationMaintenanceDescription,
                                         buttonText: TextsAsset.okay)
            return
        }
        if favButton.isHidden {
            guard let staticIp = displayingStaticIP else { return }
            staticIpDelegate?.setSelectedStaticIP(staticIP: staticIp)
        } else {
            guard let location = displayingNodeServer, let datacenter = displayingDatacenter else {
                guard let favDatacenter = displayingFavDatacenter else { return }
                favDelegate?.setSelectedFavourite(favourite: favDatacenter)
                return
            }
            delegate?.setSelectedLocationAndDatacenter(location: location, datacenter: datacenter)
        }
    }

    func isHostStillActive(hostname: String, isStaticIP _: Bool = false) -> Bool {
        let staticIPNodes = staticIpRepository.staticIPs.flatMap({ $0.nodes })
        let serversList = locationListRepository.currentLocationModels.flatMap { $0.datacenters.flatMap { $0.servers } }
        for server in serversList {
            if server.hostname == hostname {
                return true
            }
        }
        for server in staticIPNodes {
            if server.hostname == hostname && server.forceDisconnect == false {
                return true
            }
        }
        return false
    }
}
