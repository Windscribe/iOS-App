//
//  NewsFeedDataModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-11-12.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

struct NewsFeedDataModel: Identifiable {
    var id: Int
    var title: String
    var date: Date
    var description: String
    var expanded: Bool = false
    var readStatus: Bool = false
    var action: NewsFeedActionType?
    var animate: Bool = false

    var isFirst: Bool = false
    var isLast: Bool = false
}

enum NewsFeedActionType {
    case standard(ActionLinkModel)
    case promo(pcpid: String?, promoCode: String?, label: String?)

    var actionText: String {
        switch self {
        case .standard(let action):
            return action.title
        case .promo(_, _, let label):
            return label ?? ""
        }
    }
}

struct ActionLinkModel {
    var title: String
    var link: String
}

enum NewsFeedViewToLaunch: Equatable {
    case safari(URL)
    case payment(String, String?)
    case unknown
}

struct SafariItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

enum NewsFeedLoadState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}
