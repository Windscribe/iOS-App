//
//  AboutItem.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-07-28.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit

enum AboutItemCell {
    case status
    case aboutUs
    case privacyPolicy
    case terms
    case blog
    case jobs
    case softwareLicenses
    case changelog

    var title: String {
        switch self {
        case .status:
            return TextsAsset.About.status
        case .aboutUs:
            return TextsAsset.About.aboutUs
        case .privacyPolicy:
            return TextsAsset.About.privacyPolicy
        case .terms:
            return TextsAsset.About.terms
        case .blog:
            return TextsAsset.About.blog
        case .softwareLicenses:
            return TextsAsset.About.softwareLicenses
        case .jobs:
            return TextsAsset.About.jobs
        case .changelog:
            return TextsAsset.About.changelog
        }
    }

    var url: String {
        switch self {
        case .status:
            return Links.status
        case .aboutUs:
            return Links.about
        case .privacyPolicy:
            return Links.privacy
        case .terms:
            return Links.termsWindscribe
        case .blog:
            return Links.blog
        case .jobs:
            return Links.jobs
        case .softwareLicenses:
            return Links.softwareLicenses
        case .changelog:
            return Links.changelog
        }
    }
}
