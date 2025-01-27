//
//	UIView+Swizzling.swift
//	Windscribe
//
//	Created by Thomas on 26/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    static func localize() {
        let orginalSelector = #selector(awakeFromNib)
        let swizzledSelector = #selector(swizzledAwakeFromNib)

        let orginalMethod = class_getInstanceMethod(self, orginalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)

        let didAddMethod = class_addMethod(self,
                                           orginalSelector,
                                           method_getImplementation(swizzledMethod!),
                                           method_getTypeEncoding(swizzledMethod!))

        if didAddMethod {
            class_replaceMethod(self,
                                swizzledSelector,
                                method_getImplementation(orginalMethod!),
                                method_getTypeEncoding(orginalMethod!))
        } else {
            method_exchangeImplementations(orginalMethod!, swizzledMethod!)
        }
    }

    @objc func swizzledAwakeFromNib() {
        swizzledAwakeFromNib()
        switch self {
        case let txtf as UITextField:
            txtf.text = txtf.text?.localize()
            txtf.placeholder = txtf.placeholder?.localize()
        case let lbl as UILabel:
            lbl.text = lbl.text?.localize()
        case let tabbar as UITabBar:
            tabbar.items?.forEach { $0.title = $0.title?.localize() }
        case let btn as UIButton:
            btn.setTitle(btn.title(for: .normal)?.localize(), for: .normal)
        case let sgmnt as UISegmentedControl:
            (0 ..< sgmnt.numberOfSegments).forEach { sgmnt.setTitle(sgmnt.titleForSegment(at: $0)?.localize(), forSegmentAt: $0) }
        case let txtv as UITextView:
            txtv.text = txtv.text?.localize()
        default:
            break
        }
    }
}

extension String {
    func localize(comment: String = "") -> String {
        guard let bundle = Bundle.main.path(forResource: SharedSecretDefaults.shared.getSelectedLanguage(),
                                            ofType: "lproj")
        else {
            return NSLocalizedString(self, comment: comment)
        }
        let langBundle = Bundle(path: bundle)
        return NSLocalizedString(self, tableName: nil, bundle: langBundle!, comment: comment)
    }
}
