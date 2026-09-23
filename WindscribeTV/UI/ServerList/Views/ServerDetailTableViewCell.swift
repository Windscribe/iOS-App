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
    // MARK: - Properties

    let latencyRepository = Assembler.resolve(LatencyRepository.self)
    let vpnManager = Assembler.resolve(VPNManager.self)

    lazy var preferences = Assembler.resolve(Preferences.self)
    lazy var locationListRepository = Assembler.resolve(LocationListRepository.self)
    lazy var userSessionRepository: UserSessionRepository = Assembler.resolve(UserSessionRepository.self)
    lazy var staticIpRepository = Assembler.resolve(StaticIpRepository.self)
    lazy var alertManager = Assembler.resolve(AlertManager.self)

    @IBOutlet var favButton: UIButton!
    @IBOutlet var cityLabel: UILabel!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var proIcon: UIImageView!
    @IBOutlet var latencyLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var connectButtonTrailing: NSLayoutConstraint!

    weak var delegate: LocationsListTableViewDelegate?
    weak var favDelegate: FavouriteListTableViewDelegate?
    weak var staticIpDelegate: StaticIPListTableViewDelegate?

    var displayingDatacenter: DatacenterModel?
    var displayingNodeServer: LocationModel?
    var favIDs: [String] = []
    var myPreferredFocusedView: UIView?
    var isFavourited = false

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

    override var preferredFocusedView: UIView? {
        return myPreferredFocusedView
    }

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

    override var canBecomeFocused: Bool {
        return false
    }

    private var cancellables = Set<AnyCancellable>()
    private var isbtnFirst = false
    private var isbtnSecond = false
    private var isDefault = false

    // MARK: - Cell Lifecycle and Actions

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        preferences.observeFavouriteIds()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favIDs in
                guard let self else { return }
                self.favIDs = favIDs
                updateFavouriteState()
            }
            .store(in: &cancellables)
        latencyRepository.latency
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateLatency()
            }
            .store(in: &cancellables)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        displayingDatacenter = nil
        displayingNodeServer = nil
        displayingFavDatacenter = nil
        displayingStaticIP = nil
        delegate = nil
        favDelegate = nil
        staticIpDelegate = nil
        isFavourited = false
        isbtnFirst = false
        isbtnSecond = false
        myPreferredFocusedView = nil
        cityLabel.attributedText = nil
        latencyLabel.text = nil
        descriptionLabel.text = nil
        descriptionLabel.isHidden = true
        proIcon.isHidden = true
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
        guard displayingFavDatacenter != nil else { return }
        connectButtonTrailing.constant = 50
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
        updateLatency()
        updateFavouriteState()

        if let premiumOnly = displayingFavDatacenter?.isPremiumOnly, let isUserPro = userSessionRepository.sessionModel?.isPremium {
            if premiumOnly && !isUserPro {
                proIcon.isHidden = false
            } else {
                proIcon.isHidden = true
            }
        } else {
            proIcon.isHidden = true
        }
    }

    func updetaUIForStaticIP() {
        guard displayingStaticIP != nil else { return }
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
        updateLatency()
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
        favButton.isHidden = false
        connectButtonTrailing.constant = 50
        proIcon.isHidden = !datacenter.isPremiumOnly || (userSessionRepository.sessionModel?.isPremium ?? false)
        let city = datacenter.city
        let nick = datacenter.nick
        let fullText = "\(city) \(nick)"
        let attributedString = NSMutableAttributedString(string: fullText)

        let firstRange = (fullText as NSString).range(of: city)
        attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)

        let secondRange = (fullText as NSString).range(of: nick)
        attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
        cityLabel.attributedText = attributedString

        updateLatency()
        updateFavouriteState()
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

    // MARK: - Private Helpers

    private func updateFavouriteState() {
        let datacenter = displayingFavDatacenter ?? displayingDatacenter
        isFavourited = datacenter.map { favIDs.contains("\($0.id)") } ?? false
        setFavButtonImage()
    }

    private func updateLatency() {
        if let staticIP = displayingStaticIP {
            latencyLabel.font = .text(size: 30)
            let latency = staticIP.bestNode.flatMap { node in
                node.forceDisconnect ? nil : latencyRepository.getPingData(ip: node.ip1)?.latency
            }
            let latencyText = latency.map { $0 > 0 ? "\($0) MS" : "" } ?? ""
            latencyLabel.text = [latencyText, staticIP.staticIP].filter { !$0.isEmpty }.joined(separator: "  ")
            return
        }

        latencyLabel.font = .bold(size: 30)
        let datacenter = displayingFavDatacenter ?? displayingDatacenter
        let latency = datacenter?.pingServer.flatMap { latencyRepository.getPingData(ip: $0.ip)?.latency }
        latencyLabel.text = latency.map { $0 > 0 ? "\($0) MS" : "--" } ?? "--"
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
}
