//
//  MenuCategoryRowType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

protocol MenuCategoryRowType: Identifiable, CaseIterable {
    var id: Int { get }
    var title: String { get }
    var imageName: String? { get }
    var actionImageName: String? { get }
    var tintColor: Color { get }
}
