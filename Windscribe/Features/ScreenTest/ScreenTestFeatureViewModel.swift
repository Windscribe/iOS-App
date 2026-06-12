//
//  ScreenTestFeatureViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class ScreenTestFeatureViewModel {

    // MARK: - State
    var visibleItems: [ScreenTestItemType] = ScreenTestItemType.allCases
    var presentedScreen: ScreenTestRouteID?

    // MARK: - Actions

    func itemSelected(_ item: ScreenTestItemType) {
        presentedScreen = item.routeID
    }
}
