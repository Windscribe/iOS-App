//
//  UIViewController+ext.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-19.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

public extension UIStackView {
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }

    func setPadding(_ inset: UIEdgeInsets) {
        layoutMargins = inset
        isLayoutMarginsRelativeArrangement = true
    }
    
#if os(iOS)
    func setBackgroundColor(_ color: UIColor) {
        let backgroundView = UIView()
        backgroundView.backgroundColor = color
        insertSubview(backgroundView, at: 0)

        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
#endif
}
