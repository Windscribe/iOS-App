//
//  ViewLogViewController+UI.swift
//  Windscribe
//
//  Created by Yalcin on 2019-07-11.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

extension ViewLogViewController {
    func addViews() {
        logView = UITextView()
        logView.bouncesZoom = true
        logView.backgroundColor = UIColor.clear
        logView.font = UIFont.text(size: 7)
        logView.textColor = UIColor.white
        logView.isEditable = false
        logView.isSelectable = true
        logView.isUserInteractionEnabled = true

        view.addSubview(logView)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture))
        logView.addGestureRecognizer(pinchGestureRecognizer)
    }

    func addAutoLayoutConstraints() {
        logView.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints([
            NSLayoutConstraint(item: logView as Any, attribute: .top, relatedBy: .equal, toItem: backButton, attribute: .bottom, multiplier: 1.0, constant: 32),
            NSLayoutConstraint(item: logView as Any, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 16),
            NSLayoutConstraint(item: logView as Any, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: logView as Any, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: -16),
        ])
    }

    @objc func pinchGesture(gestureRecognizer: UIPinchGestureRecognizer) {
        let font = logView.font
        var pointSize = font?.pointSize
        let fontName = font?.fontName

        pointSize = min(max(gestureRecognizer.velocity * 0.5, -1.0), 1.0) + pointSize!

        if pointSize! < 6 {
            pointSize = 6
        }
        if pointSize! > 32 {
            pointSize = 32
        }
        logView.font = UIFont(name: fontName!, size: pointSize!)
    }

    func displayElementsForPrefferedAppearence() {
        // self.displayForPrefferedAppearence()
        if !themeManager.getIsDarkTheme() {
            logView.textColor = UIColor.midnight
        } else {
            logView.textColor = UIColor.white
        }
    }
}
