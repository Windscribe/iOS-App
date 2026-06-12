//
//  RobertEntryType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum RobertEntryType: MenuEntryHeaderType, Hashable, Equatable {
    case customRules

    var id: Int { 1 }
    var action: MenuEntryActionType? { .none(title: TextsAsset.Robert.manageCustomRules, parentId: id) }
    var message: String? { nil }
    var secondaryEntries: [MenuSecondaryEntryItem] { [] }
    var title: String { TextsAsset.Robert.manageCustomRules }
    var icon: String { "" }
}
