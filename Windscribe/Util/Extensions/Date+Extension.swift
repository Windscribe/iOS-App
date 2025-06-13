//
//  Date+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-18.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation

extension Date {
    var currentTimestamp: String {
        return timeIntervalSince1970.description
    }

    var currentMonth: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M"
        return dateFormatter.string(from: self)
    }

    var currentYear: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: self)
    }

    var daysSince: Int {
        let calendar = Calendar.current
        let currentDate = Date()

        guard let daysPassed = calendar.dateComponents([.day], from: self, to: currentDate).day else {
            return 0
        }

        return daysPassed
    }
}

extension DateFormatter {
    static let customNoticeFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        return numberOfDays.day ?? 0
    }
}
