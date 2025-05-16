//
//  AboutItemType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum AboutItemType: Int, MenuCategoryRowType {
    case status
    case aboutUs
    case privacyPolicy
    case terms
    case blog
    case jobs
    case softwareLicenses
    case changelog

    var id: Int { rawValue }
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

    var imageName: String? { nil }
    var actionImageName: String? { ImagesAsset.externalLink }
    var tintColor: Color { .primary }

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
