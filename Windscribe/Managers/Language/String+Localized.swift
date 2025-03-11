//
//	String+Localized.swift
//	Windscribe
//
//	Created by Thomas on 26/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func localize(comment: String = "") -> String {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let languageCode = appDelegate.languageManager.getCurrentLanguage().rawValue
            guard let bundle = Bundle.main.path(forResource: languageCode,
                                                ofType: "lproj")
            else {
                return NSLocalizedString(self, comment: comment)
            }
            let langBundle = Bundle(path: bundle)
            return NSLocalizedString(self, tableName: nil, bundle: langBundle!, comment: comment)
        }
        return self
    }
}
