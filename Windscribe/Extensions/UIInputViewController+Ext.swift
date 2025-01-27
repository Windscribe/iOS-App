//
//  UIInputViewController+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension UIInputViewController {
    func sharedApplication() throws -> UIApplication {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                return application
            }

            responder = responder?.next
        }

        throw NSError(domain: "UIInputViewController+Ext.swift",
                      code: 1,
                      userInfo: nil)
    }
}
