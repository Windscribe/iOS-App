//
//  ViewPositionReader.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-28.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct ViewFrameKey: PreferenceKey {
    typealias Value = [String: Anchor<CGRect>]

    static var defaultValue: [String: Anchor<CGRect>] = [:]

    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func readingFrame(id: String) -> some View {
        anchorPreference(key: ViewFrameKey.self, value: .bounds) { [id: $0] }
    }
}
