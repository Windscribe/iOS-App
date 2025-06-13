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
    var actionLink: ActionLinkModel?
    var animate: Bool = false

    var isFirst: Bool = false
    var isLast: Bool = false
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

enum NewsFeedLoadState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}
