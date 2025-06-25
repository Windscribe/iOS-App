//
//  DescriptionWithLearnMore.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/06/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import UIKit

struct DescriptionWithLearnMore: View {
    let description: String
    var isDarkMode: Bool
    let action: () -> Void
    var body: some View {
        Text(buildAttributedString())
            .foregroundColor(.from(.infoColor, isDarkMode))
            .font(.regular(.footnote))
            .multilineTextAlignment(.leading)
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle()) // Enables tapping in full area
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { gesture in
                                    if let range = fullText.range(of: TextsAsset.learnMore),
                                       let boundingBox = boundingRectForSubstring(fullText: fullText,
                                                                                  font: .regular(textStyle: .footnote),
                                                                                  containerWidth: geo.size.width,
                                                                                  range: NSRange(range, in: fullText)) {
                                        if boundingBox.contains(CGPoint(x: gesture.location.x, y: gesture.location.y)) {
                                            action()
                                        }
                                    }
                                }
                        )
                }
            )
    }

    private var fullText: String {
        "\(description) \(TextsAsset.learnMore)"
    }

    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(fullText)
        if let range = attributed.range(of: TextsAsset.learnMore) {
            attributed[range].foregroundColor = .learnBlue
        }
        return attributed
    }

    func boundingRectForSubstring(fullText: String, font: UIFont, containerWidth: CGFloat, range: NSRange) -> CGRect? {
        let attributedText = NSAttributedString(string: fullText, attributes: [.font: font])

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: containerWidth, height: .greatestFiniteMagnitude))

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Ensure layout is computed
        layoutManager.ensureLayout(for: textContainer)

        // Get bounding rect for glyphs in the given range
        var glyphRange = NSRange()
        layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        return boundingRect
    }
}
