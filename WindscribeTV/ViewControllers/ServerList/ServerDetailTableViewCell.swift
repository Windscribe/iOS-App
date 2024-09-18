//
//  ServerDetailTableViewCell.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 19/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

protocol ServerListTableViewDelegate: AnyObject {
    func setSelectedServerAndGroup(server: ServerModel, group: GroupModel)
    func showUpgradeView()
    func showExpiredAccountView()
    func showOutOfDataPopUp()
}

protocol FavNodesListTableViewDelegate: AnyObject {
    func setSelectedFavNode(favNode: FavNodeModel)
    func showUpgradeView()
    func showExpiredAccountView()
    func showOutOfDataPopUp()
}

protocol StaticIPListTableViewDelegate: AnyObject {
    func setSelectedStaticIP(staticIP: StaticIPModel)
}

class ServerDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var favButton: UIButton!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var proIcon: UIImageView!
    weak var delegate: ServerListTableViewDelegate?
    weak var favDelegate: FavNodesListTableViewDelegate?
    weak var staticIpDelegate: StaticIPListTableViewDelegate?

    @IBOutlet weak var latencyLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var connectButtonTrailing: NSLayoutConstraint!
    let latencyRepository = Assembler.resolve(LatencyRepository.self)
    lazy var localDB = Assembler.resolve(LocalDatabase.self)
    lazy var preferences = Assembler.resolve(Preferences.self)
    var displayingGroup: GroupModel?
    var displayingNodeServer: ServerModel?
    var favIDs: [String] = []
    let disposeBag = DisposeBag()
    let vpnManager = Assembler.resolve(VPNManager.self)

    lazy var sessionManager: SessionManagerV2 = {
        return Assembler.resolve(SessionManagerV2.self)
    }()
    var displayingFavGroup: Group? {
        didSet {
            updateUIForFavNode()
        }
    }
    var displayingStaticIP: StaticIPModel? {
        didSet {
            updetaUIForStaticIP()
        }
    }
    var isFavourited: Bool = false
    private var isbtnFirst  = false
    private var isbtnSecond = false
    private var isDefault   = false

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

        latencyLabel.font = .bold(size: 30)
        latencyLabel.textColor = .whiteWithOpacity(opacity: 0.50)
        proIcon.alpha = 0.50

        descriptionLabel.textColor = .white
        descriptionLabel.font = .text(size: 30)
        descriptionLabel.isHidden = true
        descriptionLabel.text = ""
        self.proIcon.isHidden = true
        if let premiumOnly = displayingGroup?.premiumOnly, let isUserPro = sessionManager.session?.isPremium {
            if premiumOnly && !isUserPro {
                self.proIcon.isHidden = false
            }
        }
    }

    func updateUIForFavNode() {
        if displayingFavGroup?.isInvalidated == true {
            return
        }
        self.displayingGroup = displayingFavGroup?.getGroupModel()
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
              let minTime = latencyRepository.getPingData(ip: pingIp)?.latency else {
            self.latencyLabel.text = "--"
            return
        }
        if minTime > 0 {
            self.latencyLabel.text = " \(minTime.description) MS"
        } else {
            self.latencyLabel.text = "--"
        }

        if let premiumOnly = displayingFavGroup?.premiumOnly, let isUserPro = sessionManager.session?.isPremium {
            if premiumOnly && !isUserPro {
                self.proIcon.isHidden = false
            } else {
                self.proIcon.isHidden = true
            }
        } else {
            self.proIcon.isHidden = true
        }
        preferences.observeFavouriteIds().subscribe(onNext: { favIDs in
            self.favIDs = favIDs
            if self.displayingFavGroup?.isInvalidated == false , let id = self.displayingFavGroup?.id {
                self.isFavourited = favIDs.map({ $0 }).contains("\(id)")
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
        if let bestNode = self.displayingStaticIP?.bestNode, let bestNodeHostname = bestNode.ip1, bestNode.forceDisconnect == false {
            guard let minTime = latencyRepository.getPingData(ip: bestNodeHostname)?.latency else {
                self.latencyLabel.text = " "
                return
            }

            guard let staticIp = displayingStaticIP?.staticIP else {
                self.latencyLabel.text = minTime > 0 ? "\(minTime.description) MS" : ""
                return
            }
            self.latencyLabel.text = minTime > 0 ? "\(minTime.description) MS  \(staticIp)" : " \(staticIp)"
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
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
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

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (context.previouslyFocusedView != nil) && (context.nextFocusedView != nil) {
            if context.nextFocusedView is ServerDetailTableViewCell && context.previouslyFocusedView  !=  self.favButton {
                self.isbtnFirst = true
                self.setNeedsFocusUpdate()
            }
            if context.nextFocusedView  ==  self.connectButton && context.previouslyFocusedView  ==  self.connectButton {
                self.isbtnSecond = true
                self.setNeedsFocusUpdate()
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
                    descriptionLabel.text = TvAssets.removeFromFav
                } else {
                    descriptionLabel.text = TvAssets.addToFav
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
        self.displayingGroup = group
        if let city = group.city, let nick = group.nick {
            let fullText = "\(city) \(nick)"
            let attributedString = NSMutableAttributedString(string: fullText)

            let firstRange = (fullText as NSString).range(of: city)
            attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)

            let secondRange = (fullText as NSString).range(of: nick)
            attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
            cityLabel.attributedText = attributedString
        }
        guard let pingIp = group.pingIp,
              let minTime = latencyRepository.getPingData(ip: pingIp)?.latency else {
            self.latencyLabel.text = " "
            return
        }
        if minTime > 0 {
            self.latencyLabel.text = " \(minTime.description) MS"
        } else {
            self.latencyLabel.text = "  "
        }
        preferences.observeFavouriteIds().subscribe(onNext: { favIDs in
            self.favIDs = favIDs
            if let id = group.id {
                self.isFavourited = favIDs.map({ $0 }).contains("\(id)")
                self.setupUI()
            }
        }).disposed(by: disposeBag)
    }

    @objc func favButtonTapped() {
        var group = displayingGroup
        if displayingFavGroup != nil {
            group = displayingFavGroup?.getGroupModel()
        }
        guard let group = group else {
            return
        }
        if isFavourited {
            isFavourited = false
            setFavButtonImage()
            if let groupId = group.id {
                self.preferences.removeFavouriteId("\(groupId)")
            }
        } else {
            isFavourited = true
            setFavButtonImage()
            if let groupId = group.id {
                self.preferences.addFavouriteId("\(groupId)")
            }
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
                if isPro {
                    favDelegate?.showExpiredAccountView()
                } else {
                    favDelegate?.showOutOfDataPopUp()
                }
                return
            }
            if isPro {
                delegate.showExpiredAccountView()
            } else {
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
            AlertManager.shared.showSimpleAlert(viewController: self.delegate as? UIViewController, title: TvAssets.locationMaintenanceTitle, message: TvAssets.locationMaintenanceDescription, buttonText: TextsAsset.okay)
            return
        }
        if favButton.isHidden {
            guard let staticIp = displayingStaticIP else { return }
            self.staticIpDelegate?.setSelectedStaticIP(staticIP: staticIp)
        } else {
            guard let server = displayingNodeServer, let group = displayingGroup else {
                guard let favGroup = displayingFavGroup else { return }
                if let favNode = buildFavNode(group: favGroup)?.getFavNodeModel() {
                    self.favDelegate?.setSelectedFavNode(favNode: favNode)
                }
                return
            }
            self.delegate?.setSelectedServerAndGroup(server: server, group: group)
        }
    }

    private func buildFavNode(group: Group) -> FavNode? {
        let servers = localDB.getServers() ?? []
        let server = servers.first { server in
            return server.groups.map {$0.id}.contains(group.id)
        }
        if let server = server, let node = group.nodes.randomElement() {
            return FavNode(node: node, group: group, server: server)
        }
        return nil
    }

    func isHostStillActive(hostname: String, isStaticIP: Bool = false) -> Bool {
        guard let nodesList = localDB.getServers()?.flatMap({ $0.groups }).map({ $0.nodes }),
              let  staticIPNodes = localDB.getStaticIPs()?.flatMap({ $0.nodes }) else { return false }
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
