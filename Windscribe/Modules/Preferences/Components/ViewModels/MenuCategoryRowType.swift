//
//  MenuCategoryRowType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

protocol MenuCategoryRowType: Hashable {
    var id: Int { get }
    var title: String { get }
    var imageName: String? { get }
    var actionImageName: String? { get }

    func tintColor(_ isDarkMode: Bool) -> Color
}

extension MenuCategoryRowType {
    func backgroundTintColor(_ isDarkMode: Bool) -> Color {
        tintColor(isDarkMode).opacity( isDarkMode ? 0.05 : 0.1)
    }
}

struct MenuOption: Hashable {
    let title: String
    let fieldKey: String
}
