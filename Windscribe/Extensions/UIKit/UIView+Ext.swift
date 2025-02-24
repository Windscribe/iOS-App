//
//  UIView+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-24.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Swinject
import UIKit

extension UIView {
    private static let kRotationAnimationKey = "rotationanimationkey"
    private static let kFlashAnimationKey = "flashanimationkey"
    private static let kPulseAnimationKey = "pulseanimationkey"
    private static let themeManager = Assembler.resolve(ThemeManager.self)

    func rotate() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 2
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        layer.add(rotation, forKey: UIView.kRotationAnimationKey)
    }

    func stopRotating() {
        if layer.animation(forKey: UIView.kRotationAnimationKey) != nil {
            layer.removeAnimation(forKey: UIView.kRotationAnimationKey)
        }
    }

    func makeRoundCorners(corners: UIRectCorner, radius: CGFloat) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let bezierPath = UIBezierPath(roundedRect: self.bounds,
                                          byRoundingCorners: corners,
                                          cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = bezierPath.cgPath
            self.layer.mask = mask
        }
    }

    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }

    func flash() {
        let rotation = CABasicAnimation(keyPath: "opacity")
        rotation.fromValue = 1.0
        rotation.toValue = 0.1
        rotation.duration = Double.random(in: 0.3 ... 0.7)
        rotation.isCumulative = true
        rotation.autoreverses = true
        rotation.repeatCount = 1
        layer.removeAllAnimations()
        layer.add(rotation, forKey: UIView.kFlashAnimationKey)
    }

    func pulse() {
        let rotation = CABasicAnimation(keyPath: "opacity")
        rotation.fromValue = 1.0
        rotation.toValue = 0.1
        rotation.duration = 0.5
        rotation.isCumulative = false
        rotation.autoreverses = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        layer.add(rotation, forKey: UIView.kPulseAnimationKey)
    }

    func stopPulse() {
        if layer.animation(forKey: UIView.kPulseAnimationKey) != nil {
            layer.removeAnimation(forKey: UIView.kPulseAnimationKey)
        }
    }

    func addTapGesture(tapNumber: Int = 1, target: Any, action: Selector) {
        let tap = UITapGestureRecognizer(target: target, action: action)
        tap.numberOfTapsRequired = tapNumber
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    func fitToSuperView(top: CGFloat = 0.0,
                        leading: CGFloat = 0.0,
                        bottom: CGFloat = 0.0,
                        trailing: CGFloat = 0.0) {
        guard let parentView = superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        parentView.addConstraint(NSLayoutConstraint(item: self,
                                                    attribute: .top,
                                                    relatedBy: .equal,
                                                    toItem: parentView,
                                                    attribute: .top,
                                                    multiplier: 1.0,
                                                    constant: top))
        parentView.addConstraint(NSLayoutConstraint(item: self,
                                                    attribute: .leading,
                                                    relatedBy: .equal,
                                                    toItem: parentView,
                                                    attribute: .leading,
                                                    multiplier: 1.0,
                                                    constant: leading))
        parentView.addConstraint(NSLayoutConstraint(item: parentView,
                                                    attribute: .bottom,
                                                    relatedBy: .equal,
                                                    toItem: self,
                                                    attribute: .bottom,
                                                    multiplier: 1.0,
                                                    constant: bottom))
        parentView.addConstraint(NSLayoutConstraint(item: parentView,
                                                    attribute: .trailing,
                                                    relatedBy: .equal,
                                                    toItem: self,
                                                    attribute: .trailing,
                                                    multiplier: 1.0,
                                                    constant: trailing))
    }
}

extension UIView {
    func bringToFront() {
        guard let parentView = superview else {
            return
        }
        parentView.bringSubviewToFront(self)
    }

    func sendToBack() {
        guard let parentView = superview else {
            return
        }
        parentView.sendSubviewToBack(self)
    }

    func makeTopAnchor(with view: UIView, constant: CGFloat = 0) {
        topAnchor.constraint(equalTo: view.bottomAnchor, constant: constant).isActive = true
    }

    func makeBottomAnchor(with view: UIView, constant: CGFloat = 0) {
        bottomAnchor.constraint(equalTo: view.topAnchor, constant: constant).isActive = true
    }

    func makeTrailingAnchor(with view: UIView, constant: CGFloat = 0) {
        trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: -constant).isActive = true
    }

    func makeTopAnchor(constant: CGFloat = 0) {
        guard let parentView = superview else {
            return
        }
        topAnchor.constraint(equalTo: parentView.topAnchor, constant: constant).isActive = true
    }

    func makeLeadingAnchor(constant: CGFloat = 0) {
        guard let parentView = superview else {
            return
        }
        leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: constant).isActive = true
    }

    func makeTrailingAnchor(constant: CGFloat = 0) {
        guard let parentView = superview else {
            return
        }
        trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -constant).isActive = true
    }

    func makeBottomAnchor(constant: CGFloat = 0) {
        guard let parentView = superview else {
            return
        }
        if constant > 0 {
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -constant).isActive = true
        } else {
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: constant).isActive = true
        }
    }

    func makeHeightAnchor(equalTo constant: CGFloat) {
        heightAnchor.constraint(equalToConstant: constant).isActive = true
    }

    func makeWidthAnchor(equalTo constant: CGFloat) {
        widthAnchor.constraint(equalToConstant: constant).isActive = true
    }

    func makeCenter(xConstant: CGFloat = 0, yConstant: CGFloat = 0) {
        guard let superview = superview else {
            return
        }
        centerXAnchor.constraint(equalTo: superview.centerXAnchor, constant: xConstant).isActive = true
        centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant: yConstant).isActive = true
    }

    func makeCenterYAnchor(constant: CGFloat = 0) {
        guard let superview = superview else {
            return
        }
        centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant: constant).isActive = true
    }

    func makeCenterYAnchor(with view: UIView, constant: CGFloat = 0) {
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true
    }

    func makeCenterXAnchor(constant: CGFloat = 0) {
        guard let superview = superview else {
            return
        }
        centerXAnchor.constraint(equalTo: superview.centerXAnchor, constant: constant).isActive = true
    }
}

extension UIView {
    static func divider(color: UIColor? = nil, height: CGFloat = 1) -> UIView {
        let view = UIView()
        view.backgroundColor = color ?? (themeManager.getIsDarkTheme() ? UIColor.whiteWithOpacity(opacity: 0.08) : UIColor.midnightWithOpacity(opacity: 0.08))
        view.constrainHeight(height)
        return view
    }

    func addBottomDivider(color: UIColor? = nil, height: CGFloat = 2, paddingLeft: CGFloat = 16) {
        let divider = UIView.divider(color: color, height: height)
        addSubview(divider)
        divider.anchor(left: leftAnchor,
                       bottom: bottomAnchor,
                       right: rightAnchor,
                       paddingLeft: paddingLeft)
    }

    func addTopDivider(color: UIColor? = nil, height: CGFloat = 2, paddingLeft: CGFloat = 16) {
        let divider = UIView.divider(color: color, height: height)
        addSubview(divider)
        divider.anchor(top: topAnchor,
                       left: leftAnchor,
                       right: rightAnchor,
                       paddingLeft: paddingLeft)
    }
}

extension UIView {
    @objc func updateTheme(isDark _: Bool) {}
}

extension UIView {
    func makeCorner(_ cornerRadius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
    }
}

extension UIView {
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach { addSubview($0) }
    }
}

extension UIView {

    /// Checks if the current device has a regular size class (typically iPads).
    var isRegularSizeClass: Bool {
        
#if os(iOS)
        return self.traitCollection.horizontalSizeClass == .regular
#elseif os(tvOS)
        return false
#endif
    }

    /// Checks if the device is in Portrait mode.
    var isPortrait: Bool {
#if os(iOS)
        return currentInterfaceOrientation?.isPortrait ?? false
#elseif os(tvOS)
        return false
#endif
    }

    /// Checks if the device is in Landscape mode.
    var isLandscape: Bool {
#if os(iOS)
        return currentInterfaceOrientation?.isLandscape ?? false
#elseif os(tvOS)
        return true
#endif
    }
    
#if os(iOS)
    /// Gets the current interface orientation safely
    private var currentInterfaceOrientation: UIInterfaceOrientation? {
        return window?.windowScene?.interfaceOrientation ??
               UIApplication.shared.connectedScenes
                   .compactMap { ($0 as? UIWindowScene)?.interfaceOrientation }
                   .first
    }
#endif
}
