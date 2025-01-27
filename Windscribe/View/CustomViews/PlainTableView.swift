//
//  PlainTableView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import ExpyTableView
import UIKit

public class PlainTableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        separatorStyle = .none
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        rowHeight = 50
        estimatedRowHeight = 50
        backgroundColor = UIColor.clear
        layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class PlainExpyTableView: ExpyTableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        separatorStyle = .none
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        rowHeight = 50
        estimatedRowHeight = 50
        backgroundColor = UIColor.clear
        layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func collapseExpandedSections() {
        for section in expandedSections {
            collapse(section.key)
        }
    }
}
