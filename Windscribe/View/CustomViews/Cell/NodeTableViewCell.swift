//
//  NodeTableViewCell.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-23.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Realm
import RealmSwift
import RxSwift
import Swinject
import UIKit

class NodeTableViewCell: BaseNodeTableViewCell {
    var favButton: UIButton!
    var cityNameLabel: UILabel!
    var nickNameLabel: UILabel!
    lazy var localDB = Assembler.resolve(LocalDatabase.self)
    lazy var preferences = Assembler.resolve(Preferences.self)
    lazy var sessionManager = Assembler.resolve(SessionManagerV2.self)
    let disposeBag = DisposeBag()
    var favNodes: [FavNode] = []
    var displayingGroup: GroupModel? {
        didSet {
            updateUI()
        }
    }

    var displayingNodeServer: ServerModel?
    var favourited: Bool = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        setPressState(active: true)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        setPressState(active: false)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        setPressState(active: false)
    }

    private func setPressState(active: Bool) {
        if active {
            cityNameLabel.layer.opacity = 1
            nickNameLabel.layer.opacity = 1
            favButton.layer.opacity = 1
            signalBarsIcon.layer.opacity = 1
            linkSpeedIcon.layer.opacity = 1
            latencyLabel.layer.opacity = 1
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.cityNameLabel.layer.opacity = 0.4
                self?.nickNameLabel.layer.opacity = 0.4
                self?.favButton.layer.opacity = 0.4
                self?.signalBarsIcon.layer.opacity = 0.4
                self?.linkSpeedIcon.layer.opacity = 0.4
                self?.latencyLabel.layer.opacity = 0.4
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.white

        favButton = ImageButton()
        favButton.addTarget(self, action: #selector(favButtonTapped), for: .touchUpInside)
        favButton.setImage(emptyFavImage, for: .normal)
        favButton.layer.opacity = 0.4
        contentView.addSubview(favButton)

        cityNameLabel = UILabel()
        cityNameLabel.font = UIFont.bold(size: 14)
        cityNameLabel.layer.opacity = 0.4
        cityNameLabel.textColor = UIColor.midnight
        addSubview(cityNameLabel)

        nickNameLabel = UILabel()
        nickNameLabel.font = UIFont.text(size: 14)
        nickNameLabel.layer.opacity = 0.4
        nickNameLabel.textColor = UIColor.midnight
        addSubview(nickNameLabel)

        latencyBackground = UIView()
        latencyBackground.backgroundColor = UIColor.midnight
        latencyBackground.layer.opacity = 0.05
        latencyBackground.layer.cornerRadius = 8
        latencyBackground.clipsToBounds = true
        addSubview(latencyBackground)

        latencyLabel = UILabel()
        latencyLabel.font = UIFont.bold(size: 12)
        latencyLabel.layer.opacity = 0.4
        latencyLabel.textColor = UIColor.midnight
        addSubview(latencyLabel)

        signalBarsIcon = UIImageView()
        signalBarsIcon.layer.opacity = 0.5
        addSubview(signalBarsIcon)

        addAutoLayoutConstraints()
    }

    func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(onNext: { isDark in
            if !isDark {
                self.backgroundColor = UIColor.white
                self.cellDivider.backgroundColor = UIColor.midnight
                self.cityNameLabel.textColor = UIColor.midnight
                self.nickNameLabel.textColor = UIColor.midnight
                self.latencyLabel.textColor = UIColor.midnight
                self.latencyBackground.backgroundColor = UIColor.midnight
                self.linkSpeedIcon.image = self.tenGigIcon
            } else {
                self.backgroundColor = UIColor.lightMidnight
                self.cellDivider.backgroundColor = UIColor.white
                self.cityNameLabel.textColor = UIColor.white
                self.nickNameLabel.textColor = UIColor.white
                self.latencyLabel.textColor = UIColor.white
                self.latencyBackground.backgroundColor = UIColor.white
                self.linkSpeedIcon.image = self.tenGigIcon
            }
        }).disposed(by: disposeBag)
        preferences.getShowServerHealth().subscribe(onNext: { serverHealth in
            if let serverHealth = serverHealth {
                if serverHealth {
                    self.serverHealthView.health = self.displayingGroup?.health
                } else {
                    self.serverHealthView.health = 0
                }
            }
        }).disposed(by: disposeBag)
        preferences.getLatencyType().subscribe(onNext: { latency in
            if latency == Fields.Values.ms {
                self.latencyBackground.isHidden = false
                self.latencyLabel.isHidden = false
                self.signalBarsIcon.isHidden = true
            } else {
                self.signalBarsIcon.isHidden = false
                self.latencyBackground.isHidden = true
                self.latencyLabel.isHidden = true
            }
        }).disposed(by: disposeBag)
        localDB.getFavNode().subscribe(onNext: { favNodes in
            self.favNodes = favNodes
        }).disposed(by: disposeBag)
    }

    func addAutoLayoutConstraints() {
        favButton.translatesAutoresizingMaskIntoConstraints = false
        cityNameLabel.translatesAutoresizingMaskIntoConstraints = false
        nickNameLabel.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: favButton as Any, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: favButton as Any, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: favButton as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: favButton as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 32),
        ])
        addConstraints([
            NSLayoutConstraint(item: cityNameLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: favButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: cityNameLabel as Any, attribute: .left, relatedBy: .equal, toItem: favButton, attribute: .right, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: nickNameLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: favButton, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: nickNameLabel as Any, attribute: .left, relatedBy: .equal, toItem: cityNameLabel, attribute: .right, multiplier: 1.0, constant: 5),
        ])
    }

    func updateUI() {
        latencyLabel.text = ""
        favButton.isEnabled = true
        nickNameLabel.isEnabled = true
        cityNameLabel.isEnabled = true
        linkSpeedIcon.isHidden = true
        favButton.setImage(emptyFavImage, for: .normal)

        if let pingIp = displayingGroup?.pingIp {
            displayLatencyValues(pingIp: pingIp)
        }

        if let cityName = displayingGroup?.city,
           let nickName = displayingGroup?.nick
        {
            cityNameLabel.text = cityName
            nickNameLabel.text = nickName
        }

        if let isGroupProOnly = displayingGroup?.premiumOnly,
           let isUserPro = sessionManager.session?.isPremium
        {
            if isGroupProOnly && !isUserPro {
                favButton.setImage(proNodeIconImage, for: .normal)
            } else {
                if let bestNode = displayingGroup?.bestNode,
                   let bestNodeHostname = displayingGroup?.bestNodeHostname,
                   bestNode.forceDisconnect == false && isHostStillActive(hostname: bestNodeHostname),
                   bestNodeHostname != ""
                {
                } else {
                    nickNameLabel.isEnabled = false
                    cityNameLabel.isEnabled = false
                    favButton.isEnabled = false
                    favButton.setImage(locationDownIcon, for: .normal)
                    signalBarsIcon.image = cellSignalBarsDown
                    latencyLabel.text = "  --  "
                    isUserInteractionEnabled = true
                }
            }
        }
        if favourited {
            favButton.setImage(fullFavImage, for: .normal)
        }
        linkSpeedIcon.isHidden = displayingGroup?.linkSpeed != "10000"
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

    @objc func favButtonTapped() {
        if favButton.image(for: .normal) != proNodeIconImage {
            guard let group = displayingGroup, let server = displayingNodeServer else { return }
            if (favButton.imageView?.image?.cgImage == fullFavImage?.cgImage) || (favButton.imageView?.image == fullFavImage) {
                let yesAction = UIAlertAction(title: TextsAsset.remove,
                                              style: .destructive)
                { [weak self] _ in
                    self?.favButton.setImage(self?.emptyFavImage, for: .normal)
                    if let groupId = group.id,
                       let favNodeHostname = self?.favNodes.filter({ $0.groupId == "\(groupId)" }).first?.hostname
                    {
                        self?.localDB.removeFavNode(hostName: favNodeHostname)
                    }
                }
                AlertManager.shared.showAlert(title: TextsAsset.RemoveFavNode.title,
                                              message: TextsAsset.RemoveFavNode.message,
                                              buttonText: TextsAsset.cancel, actions: [yesAction])

            } else {
                favButton.setImage(fullFavImage, for: .normal)
                if let bestNode = group.bestNode {
                    let favNode = FavNode(node: bestNode, group: group, server: server)
                    localDB.saveFavNode(favNode: favNode).disposed(by: disposeBag)
                }
            }
        }
    }
}

class BaseNodeTableViewCell: WTableViewCell {
    var latencyLabel: UILabel!
    var latencyBackground: UIView!
    var signalBarsIcon: UIImageView!
    var cellDivider = UIView()
    var linkSpeedIcon: UIImageView!
    var serverHealthView = ServerHealthView()

    let latencyRepository = Assembler.resolve(LatencyRepository.self)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        latencyBackground = UIView()
        latencyBackground.backgroundColor = UIColor.midnight
        latencyBackground.layer.opacity = 0.05
        latencyBackground.layer.cornerRadius = 8
        latencyBackground.clipsToBounds = true
        addSubview(latencyBackground)

        latencyLabel = UILabel()
        latencyLabel.font = UIFont.bold(size: 12)
        latencyLabel.layer.opacity = 0.4
        latencyLabel.textColor = UIColor.midnight
        addSubview(latencyLabel)

        linkSpeedIcon = UIImageView()
        linkSpeedIcon.image = tenGigIcon
        linkSpeedIcon.layer.opacity = 0.4
        linkSpeedIcon.isHidden = true
        addSubview(linkSpeedIcon)

        addSubview(serverHealthView)

        signalBarsIcon = UIImageView()
        signalBarsIcon.layer.opacity = 0.4
        signalBarsIcon.image = UIImage(named: ImagesAsset.CellSignalBars.full)
        addSubview(signalBarsIcon)

        cellDivider.layer.opacity = 0.05
        cellDivider.backgroundColor = UIColor.black
        addSubview(cellDivider)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        latencyBackground.translatesAutoresizingMaskIntoConstraints = false
        latencyLabel.translatesAutoresizingMaskIntoConstraints = false
        signalBarsIcon.translatesAutoresizingMaskIntoConstraints = false
        cellDivider.translatesAutoresizingMaskIntoConstraints = false
        linkSpeedIcon.translatesAutoresizingMaskIntoConstraints = false
        serverHealthView.translatesAutoresizingMaskIntoConstraints = false

        addConstraints([
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: latencyBackground as Any, attribute: .width, relatedBy: .equal, toItem: latencyLabel, attribute: .width, multiplier: 1.0, constant: 0),
        ])
        addConstraints([
            NSLayoutConstraint(item: latencyLabel as Any, attribute: .centerY, relatedBy: .equal, toItem: latencyBackground, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: latencyLabel as Any, attribute: .centerX, relatedBy: .equal, toItem: latencyBackground, attribute: .centerX, multiplier: 1.0, constant: 0),
        ])
        addConstraints([
            NSLayoutConstraint(item: linkSpeedIcon as Any, attribute: .centerY, relatedBy: .equal, toItem: latencyBackground, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: linkSpeedIcon as Any, attribute: .right, relatedBy: .equal, toItem: latencyBackground, attribute: .left, multiplier: 1.0, constant: -13),
            NSLayoutConstraint(item: linkSpeedIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: linkSpeedIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -16),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: signalBarsIcon as Any, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 16),
        ])
        addConstraints([
            NSLayoutConstraint(item: cellDivider as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
        ])
        addConstraints([
            NSLayoutConstraint(item: cellDivider as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: cellDivider as Any, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0),
        ])
        addConstraints([
            NSLayoutConstraint(item: serverHealthView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 2),
            NSLayoutConstraint(item: serverHealthView as Any, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -2),
            NSLayoutConstraint(item: serverHealthView as Any, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 24),
            NSLayoutConstraint(item: serverHealthView as Any, attribute: .right, relatedBy: .equal, toItem: signalBarsIcon, attribute: .left, multiplier: 1.0, constant: 0),
        ])
    }

    func displayLatencyValues(pingIp: String) {
        guard let minTime = latencyRepository.getPingData(ip: pingIp)?.latency else {
            latencyLabel.text = "  --  "
            signalBarsIcon.image = cellSignalBarsFull
            return
        }
        latencyLabel.text = "  \(minTime.description)  "
        if minTime <= 0 {
            latencyLabel.text = "  --  "
        }
        switch getSignalLevel(minTime: minTime) {
        case 1:
            signalBarsIcon.image = cellSignalBarsLow
        case 2:
            signalBarsIcon.image = cellSignalBarsMed
        case 3:
            signalBarsIcon.image = cellSignalBarsFull
        default:
            signalBarsIcon.image = cellSignalBarsFull
        }
    }
}

class FavNodeTableViewCell: NodeTableViewCell {
    var displayingFavNode: FavNodeModel? {
        didSet {
            updateUIForFavNode()
        }
    }

    func updateUIForFavNode() {
        latencyLabel.text = ""
        favButton.setImage(fullFavImage, for: .normal)
        guard let cityName = displayingFavNode?.cityName, let nickName = displayingFavNode?.nickName else { return }
        cityNameLabel.text = cityName
        nickNameLabel.text = nickName
        guard let pingIp = displayingFavNode?.pingIp else { return }
        displayLatencyValues(pingIp: pingIp)
        linkSpeedIcon.isHidden = displayingFavNode?.linkSpeed != "10000"
        preferences.getShowServerHealth().subscribe(onNext: { serverHealth in
            if let serverHealth = serverHealth {
                if serverHealth {
                    self.serverHealthView.health = self.displayingFavNode?.health
                } else {
                    self.serverHealthView.health = 0
                }
            }
        }).disposed(by: disposeBag)
    }

    @objc override func favButtonTapped() {
        guard let node = displayingFavNode else { return }
        let yesAction = UIAlertAction(title: TextsAsset.remove,
                                      style: .destructive)
        { _ in
            self.favButton.setImage(self.emptyFavImage, for: .normal)
            if let groupId = node.groupId,
               let favNodeHostname = self.favNodes.filter({ $0.groupId == "\(groupId)" }).first?.hostname
            {
                self.localDB.removeFavNode(hostName: favNodeHostname)
            }
        }
        AlertManager.shared.showAlert(title: TextsAsset.RemoveFavNode.title,
                                      message: TextsAsset.RemoveFavNode.message,
                                      buttonText: TextsAsset.cancel, actions: [yesAction])
    }
}
