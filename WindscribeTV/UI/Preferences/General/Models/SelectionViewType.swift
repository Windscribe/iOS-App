//
//  SelectionViewType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

protocol SelectionViewType {
    var asset: String { get }
    var title: String { get }
    var description: String { get }
    var listOption: [String] { get }
    var type: SelectableViewType { get }
}

enum SelectableViewType {
    case selection
    case direction
    case directionWithoutIcon
}
