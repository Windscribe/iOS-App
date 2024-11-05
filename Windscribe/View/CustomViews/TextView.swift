//
//  TextView.swift
//  Windscribe
//
//  Created by Yalcin on 2021-01-11.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import UIKit

class LinkTextView: UITextView {
    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let tapLocation = point.applying(CGAffineTransform(translationX: -textContainerInset.left, y: -textContainerInset.top))
        let characterAtIndex = layoutManager.characterIndex(for: tapLocation, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        let linkAttributeAtIndex: Any?
        if characterAtIndex == 0 {
            linkAttributeAtIndex = nil
        } else {
            linkAttributeAtIndex = textStorage.attribute(.link, at: characterAtIndex, effectiveRange: nil)
        }

        // Returns true for points located on linked text
        return linkAttributeAtIndex != nil
    }

    override func becomeFirstResponder() -> Bool {
        // Returning false disables double-tap selection of link text
        return false
    }
}
