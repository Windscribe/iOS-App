//
//  PlainTableView.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-31.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import ExpyTableView

public class PlainTableView: UITableView {

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.separatorStyle = .none
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.rowHeight = 50
        self.estimatedRowHeight = 50
        self.backgroundColor = UIColor.clear
        self.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        self.layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

class PlainExpyTableView: ExpyTableView {

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.separatorStyle = .none
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.rowHeight = 50
        self.estimatedRowHeight = 50
        self.backgroundColor = UIColor.clear
        self.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        self.layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func collapseExpandedSections() {
        for section in self.expandedSections {
            self.collapse(section.key)
        }
    }
}
