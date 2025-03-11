//
//  NSDate+Ext.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-03-08.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

extension NSDate {
    func currentTimestamp() -> String {
        return NSDate().timeIntervalSince1970.description
    }

    func today() -> String {
        let dateFormat = "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: self as Date)
    }
}
