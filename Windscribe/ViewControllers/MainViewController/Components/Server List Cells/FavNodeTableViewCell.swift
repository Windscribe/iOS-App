//
//  FavNodeTableViewCell.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import RealmSwift
import UIKit
import Swinject
import RxSwift

class FavNodeCellModel: BaseNodeCellViewModel {
    var displayingFavNode: FavNodeModel?
    var latencyRepository = Assembler.resolve(LatencyRepository.self)

    init(displayingFavNode: FavNodeModel?) {
        super.init()
        self.displayingFavNode = displayingFavNode
        if let pingIP = displayingFavNode?.pingIp {
            minTime = latencyRepository.getPingData(ip: pingIP)?.latency ?? minTime
        }
    }

    override var serverHealth: CGFloat {
        CGFloat(self.displayingFavNode?.health ?? 0)
    }

    override var groupId: String {
        displayingFavNode?.groupId ?? ""
    }

    override var name: String {
        displayingFavNode?.cityName ?? ""
    }

    override var nickName: String {
        displayingFavNode?.nickName ?? ""
    }

    override func favoriteSelected() {
        guard let node = displayingFavNode else { return }
        let yesAction = UIAlertAction(title: TextsAsset.remove, style: .destructive) { _ in
            self.updateUISubject.onNext(())
            if let groupId = node.groupId,
               let favNodeHostname = self.favNodes.filter({ $0.groupId == "\(groupId)" }).first?.hostname {
                self.localDB.removeFavNode(hostName: favNodeHostname)
            }
        }
        AlertManager.shared.showAlert(title: TextsAsset.RemoveFavNode.title,
                                      message: TextsAsset.RemoveFavNode.message,
                                      buttonText: TextsAsset.cancel, actions: [yesAction])
    }
}

class FavNodeTableViewCell: BaseNodeCell {
    var favCellViewModel: FavNodeCellModel? {
        didSet {
            baseNodeCellViewModel = favCellViewModel
        }
    }
}
