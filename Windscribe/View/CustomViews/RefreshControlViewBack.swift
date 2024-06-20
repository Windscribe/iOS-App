//
//  RefreshControlViewBack.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-07.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

class RefreshControlViewBack: UIView {

    var label: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        label = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        label.font = UIFont.bold(size: 12)
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.white
        self.addSubview(label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
