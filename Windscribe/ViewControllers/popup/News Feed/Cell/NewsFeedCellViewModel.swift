//
//  NewsFeedCellViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 12/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxDataSources

class NewsFeedCellViewModel: Equatable {
    static func == (lhs: NewsFeedCellViewModel, rhs: NewsFeedCellViewModel) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.collapsed == rhs.collapsed
    }

    let id: Int?
    let title: String?
    let message: String?
    let action: NoticeAction?
    var collapsed: Bool
    var isRead: Bool
    var isUserPro: Bool

    init(notice: Notice, collapsed: Bool, isRead: Bool, isUserPro: Bool) {
        id = notice.id
        title = notice.title
        message = notice.message
        action = notice.action
        self.collapsed = collapsed
        self.isRead = isRead
        self.isUserPro = isUserPro
    }

    func setCollapsed(collapsed: Bool) {
        self.collapsed = collapsed
        isRead = true
    }
}

extension NewsFeedCellViewModel: IdentifiableType {
    typealias Identity = Int

    var identity: Identity {
        return id ?? 0
    }
}

struct NewsSection {
    typealias Item = NewsFeedCellViewModel
    var items: [NewsFeedCellViewModel]
    var name: String = ""

    init(items: [Item]) {
        self.items = items
    }
}

extension NewsSection: AnimatableSectionModelType {
    init(original: NewsSection, items: [Item]) {
        self = original
        self.items = items
    }

    typealias Identity = Int

    var identity: Identity {
        return items.first?.id ?? 0
    }
}
