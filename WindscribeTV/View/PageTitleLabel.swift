//
//  PageTitleLabel.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 19/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit

class PageTitleLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        self.font = UIFont.bold(size: 92)
        self.textColor = .whiteWithOpacity(opacity: 0.24)
    }

}
