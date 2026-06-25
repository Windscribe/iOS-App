//
//  OptionalPill.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-10.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

struct OptionalPill: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    var body: some View {
        Text(TextsAsset.optional)
            .font(.regular(.footnote))
            .foregroundColor(.from(.iconColor, lookAndFeel.isDarkMode).opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.from(.backgroundColor, lookAndFeel.isDarkMode))
            .clipShape(Capsule())
    }
}
