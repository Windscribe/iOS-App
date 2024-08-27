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

class ServerDetailTableViewCell: UITableViewCell {
    @IBOutlet weak var favButton: UIButton!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    
    @IBOutlet weak var latencyLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var connectButtonTrailing: NSLayoutConstraint!
    let latencyRepository = Assembler.resolve(LatencyRepository.self)
    lazy var localDB = Assembler.resolve(LocalDatabase.self)
    var displayingGroup: GroupModel?
    var displayingNodeServer: ServerModel?
    var favNodes: [FavNode] = []
    let disposeBag = DisposeBag()
    var displayingFavNode: FavNodeModel? {
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

    override var preferredFocusEnvironments: [UIFocusEnvironment]{
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

        cityLabel.textColor = .whiteWithOpacity(opacity: 0.50)
        
        latencyLabel.font = .bold(size: 30)
        latencyLabel.textColor = .whiteWithOpacity(opacity: 0.50)
        
        descriptionLabel.textColor = .white
        descriptionLabel.font = .text(size: 30)
        descriptionLabel.isHidden = true
        descriptionLabel.text = ""
    }

    func updateUIForFavNode() {
        connectButtonTrailing.constant = 0
        favButton.isHidden = false
        if let city = displayingFavNode?.cityName, let nick = displayingFavNode?.nickName {
            let fullText = "\(city) \(nick)"
            let attributedString = NSMutableAttributedString(string: fullText)
                    
            let firstRange = (fullText as NSString).range(of: city)
            attributedString.addAttribute(.font, value: UIFont.bold(size: 45), range: firstRange)
                    
            let secondRange = (fullText as NSString).range(of: nick)
            attributedString.addAttribute(.font, value: UIFont.text(size: 45), range: secondRange)
            cityLabel.attributedText = attributedString
        }
        guard let pingIp = displayingFavNode?.pingIp,
              let minTime = latencyRepository.getPingData(ip: pingIp)?.latency else {
            self.latencyLabel.text = "  --  "
            return
        }
        if minTime > 0 {
            self.latencyLabel.text = " \(minTime.description) MS"
        } else {
            self.latencyLabel.text = "  --  "
        }
        localDB.getFavNode().subscribe(onNext: { favNodes in
            self.favNodes = favNodes
            if let id =  self.displayingFavNode?.groupId {
                self.isFavourited = favNodes.map({ $0.groupId }).contains("\(id)")
                self.setFavButtonImage()
            }
        }).disposed(by: disposeBag)
    }
    
    func updetaUIForStaticIP() {
        favButton.isHidden = true
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
                self.latencyLabel.text = "  --  "
                return
            }
            
            guard let staticIp = displayingStaticIP?.staticIP else {
                self.latencyLabel.text = minTime > 0 ? "\(minTime.description) MS" : "--"
                return
            }
            self.latencyLabel.text = minTime > 0 ? "\(minTime.description) MS  \(staticIp)" : " --  \(staticIp)"
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

    override var canBecomeFocused: Bool{
            return false
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if (context.previouslyFocusedView != nil) && (context.nextFocusedView != nil){
            if context.nextFocusedView is ServerDetailTableViewCell && context.previouslyFocusedView  !=  self.favButton {
                self.isbtnFirst = true
                self.setNeedsFocusUpdate()
            }
            if context.nextFocusedView  ==  self.connectButton && context.previouslyFocusedView  ==  self.connectButton{
                self.isbtnSecond = true
                self.setNeedsFocusUpdate()
            }
        }
        if connectButton.isFocused || favButton.isFocused {
            cityLabel.textColor = .white
            latencyLabel.textColor = .white
            descriptionLabel.isHidden = false
            if connectButton.isFocused {
                descriptionLabel.text = TextsAsset.connect
            } else if favButton.isFocused{
                if isFavourited {
                    descriptionLabel.text = TvAssets.removeFromFav
                } else {
                    descriptionLabel.text = TvAssets.addToFav
                }
            }
        } else {
            cityLabel.textColor = .whiteWithOpacity(opacity: 0.50)
            latencyLabel.textColor = .whiteWithOpacity(opacity: 0.50)
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
            self.latencyLabel.text = "  --  "
            return
        }
        if minTime > 0 {
            self.latencyLabel.text = " \(minTime.description) MS"
        } else {
            self.latencyLabel.text = "  --  "
        }
        localDB.getFavNode().subscribe(onNext: { favNodes in
            self.favNodes = favNodes
            if let id =  group.id {
                self.isFavourited = favNodes.map({ $0.groupId }).contains("\(id)")
                self.setupUI()
            }
        }).disposed(by: disposeBag)
    }

    @objc func favButtonTapped() {
        guard let group = displayingGroup, let server = displayingNodeServer else {
            guard let node = displayingFavNode else { return }
            if let groupId = node.groupId,
               let favNodeHostname = self.favNodes.filter({$0.groupId == "\(groupId)"}).first?.hostname {
                self.localDB.removeFavNode(hostName: favNodeHostname)
            }
            return
        }
        if isFavourited {
            isFavourited = false
            setFavButtonImage()
            if let groupId = group.id,
               let favNodeHostname = self.favNodes.filter({$0.groupId == "\(groupId)"}).first?.hostname {
                self.localDB.removeFavNode(hostName: favNodeHostname)
            }

        } else {
            isFavourited = true
            setFavButtonImage()
            if let bestNode = group.bestNode {
                let favNode = FavNode(node: bestNode, group: group, server: server)
                localDB.saveFavNode(favNode: favNode).disposed(by: disposeBag)
            }
        }
    }
    
}
