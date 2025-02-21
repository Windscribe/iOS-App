//
//  UpgradeSuccessViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

class UpgradeSuccessViewModel {
    let featureTitles = BehaviorSubject<[String]>(value: [
        TextsAsset.UpgradeView.planBenefitSuccessShareDevices,
        TextsAsset.UpgradeView.planBenefitSuccessShareLocation,
        TextsAsset.UpgradeView.planBenefitSuccessShareBandwidth
    ])

    let shareOptions = BehaviorSubject<[ShareOption]>(value: [
        ShareOption(title: TextsAsset.UpgradeView.planBenefitJoinDiscord,
                    iconName: "discord-icon",
                    url: URL(string: Links.discord)),
        ShareOption(title: TextsAsset.UpgradeView.planBenefitJoinReddit,
                    iconName: "reddit-icon",
                    url: URL(string: Links.reddit)),
        ShareOption(title: TextsAsset.UpgradeView.planBenefitFindUsYoutube,
                    iconName: "youtube-icon",
                    url: URL(string: Links.youtube)),
        ShareOption(title: TextsAsset.UpgradeView.planBenefitFollowUsX,
                    iconName: "x-icon",
                    url: URL(string: Links.twitterX))
    ])
}
