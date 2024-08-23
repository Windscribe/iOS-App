//
//  HomeRouter.swift
//  WindscribeTV
//
//  Created by Ginder Singh on 2024-08-18.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
class HomeRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case .preferences:
            let vc = Assembler.resolve(PreferencesMainViewController.self)
            from.present(vc, animated: true)
        case let .upgrade(promoCode, pcpID):
            let vc = Assembler.resolve(UpgradePopViewController.self)
            from.present(vc, animated: true)
        case .support:
            let vc: BasePopUpViewController = Assembler.resolve(BasePopUpViewController.self)
            vc.viewModel?.setPopupType(with: .support)
            from.present(vc, animated: true)
        case let .error(body):
            let vc: BasePopUpViewController = Assembler.resolve(BasePopUpViewController.self)
            vc.viewModel?.setPopupType(with: .error(body))
            from.present(vc, animated: true)
        case .rateUs:
            let vc: RatePopupViewController = Assembler.resolve(RatePopupViewController.self)
            vc.viewModel?.setPopupType(with: .rateUs)
            from.present(vc, animated: true)
        case .getMoreData:
            let vc: GetMoreDataPopupViewController = Assembler.resolve(GetMoreDataPopupViewController.self)
            vc.viewModel?.setPopupType(with: .getMoreData)
            from.present(vc, animated: true)
        case .confirmEmail:
            let vc: ConfirmEmailPopupViewController = Assembler.resolve(ConfirmEmailPopupViewController.self)
            vc.viewModel?.setPopupType(with: .confirmEmail)
            from.present(vc, animated: true)
        case .addEmail:
            let vc: AddEmailPopupViewController = Assembler.resolve(AddEmailPopupViewController.self)
            vc.viewModel?.setPopupType(with: .addeEmail)
            from.present(vc, animated: true)
        case .newsFeed:
            let vc: NewsFeedViewController = Assembler.resolve(NewsFeedViewController.self)
            from.present(vc, animated: true)
        case .serverList:
            let vc = Assembler.resolve(ServerListViewController.self)
            let transition = CATransition()
            transition.duration = 0.5
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = CATransitionType.moveIn
            transition.subtype = CATransitionSubtype.fromTop
            from.view.layer.add(transition, forKey: nil)
            from.present(vc, animated: true)
            
        default: ()
        }
    }
}
