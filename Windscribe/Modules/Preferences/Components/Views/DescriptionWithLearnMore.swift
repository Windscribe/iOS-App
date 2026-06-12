//
//  DescriptionWithLearnMore.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/06/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

struct DescriptionWithLearnMore: View {
    @Environment(\.lookAndFeel) private var lookAndFeel

    let description: String
    let action: () -> Void

    var body: some View {
        Text(buildAttributedString())
            .foregroundColor(.from(.infoColor, lookAndFeel.isDarkMode))
            .font(.regular(.footnote))
            .multilineTextAlignment(.leading)
            .environment(\.openURL, OpenURLAction { _ in
                action()
                return .handled
            })
    }

    private var fullText: String {
        "\(description) \(TextsAsset.learnMore)"
    }

    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(fullText)
        if let range = attributed.range(of: TextsAsset.learnMore) {
            attributed[range].foregroundColor = .learnBlue
            attributed[range].link = URL(string: "learn-more://")
        }
        return attributed
    }
}
