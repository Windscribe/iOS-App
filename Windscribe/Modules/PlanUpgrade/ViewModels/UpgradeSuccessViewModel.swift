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
                    iconName: ImagesAsset.Subscriptions.discordIcon,
                    url: URL(string: Links.discord)),
        ShareOption(title: TextsAsset.UpgradeView.planBenefitJoinReddit,
                    iconName: ImagesAsset.Subscriptions.redditIcon,
                    url: URL(string: Links.reddit)),
        ShareOption(title: TextsAsset.UpgradeView.planBenefitFindUsYoutube,
                    iconName: ImagesAsset.Subscriptions.youtubeIcon,
                    url: URL(string: Links.youtube)),
        ShareOption(title: TextsAsset.UpgradeView.planBenefitFollowUsX,
                    iconName: ImagesAsset.Subscriptions.xIcon,
                    url: URL(string: Links.twitterX))
    ])
}
