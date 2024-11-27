//
//  NewsFeedData.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-11-12.
//  Copyright © 2024 Windscribe. All rights reserved.
//
struct NewsFeedData {
    var id: Int
    var title: String
    var description: String
    var expanded: Bool = false
    var readStatus: Bool = false
    var actionLink: ActionLink?
    var animate: Bool = false
}

struct ActionLink {
    var title: String
    var link: String
}
