import UIKit

public struct AnchoredConstraints {
    public var top, leading, bottom, trailing, width, height: NSLayoutConstraint?
}

extension UIView {

    public func anchorWithNormalMargin(top: NSLayoutYAxisAnchor? = nil,
                                       left: NSLayoutXAxisAnchor? = nil,
                                       bottom: NSLayoutYAxisAnchor? = nil,
                                       right: NSLayoutXAxisAnchor? = nil,
                                       width: CGFloat? = nil,
                                       height: CGFloat? = nil) {
        anchor(top: top,
               left: left,
               bottom: bottom,
               right: right,
               paddingTop: (top != nil) ? 24 : 0,
               paddingLeft: (left != nil) ? 24 : 0,
               paddingBottom: (bottom != nil) ? 24 : 0,
               paddingRight: (right != nil) ? 24 : 0,
               width: width,
               height: height)
    }

    public func anchorWithSmallMargin(top: NSLayoutYAxisAnchor? = nil,
                                      left: NSLayoutXAxisAnchor? = nil,
                                      bottom: NSLayoutYAxisAnchor? = nil,
                                      right: NSLayoutXAxisAnchor? = nil,
                                      width: CGFloat? = nil,
                                      height: CGFloat? = nil) {
        anchor(top: top,
               left: left,
               bottom: bottom,
               right: right,
               paddingTop: (top != nil) ? 16 : 0,
               paddingLeft: (left != nil) ? 24 : 0,
               paddingBottom: (bottom != nil) ? 16 : 0,
               paddingRight: (right != nil) ? 24 : 0,
               width: width,
               height: height)
    }

    public func anchor(top: NSLayoutYAxisAnchor? = nil,
                       left: NSLayoutXAxisAnchor? = nil,
                       bottom: NSLayoutYAxisAnchor? = nil,
                       right: NSLayoutXAxisAnchor? = nil,
                       paddingTop: CGFloat = 0,
                       paddingLeft: CGFloat = 0,
                       paddingBottom: CGFloat = 0,
                       paddingRight: CGFloat = 0,
                       width: CGFloat? = nil,
                       height: CGFloat? = nil) {

        translatesAutoresizingMaskIntoConstraints = false

        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }

        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }

        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }

        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }

        if let width = width {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }

        if let height = height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    public func centerX(inView view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    public func centerY(inView view: UIView, leftAnchor: NSLayoutXAxisAnchor? = nil,
                        paddingLeft: CGFloat = 0, constant: CGFloat = 0) {

        translatesAutoresizingMaskIntoConstraints = false
        centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant).isActive = true

        if let left = leftAnchor {
            anchor(left: left, paddingLeft: paddingLeft)
        }
    }

    public func setDimensions(height: CGFloat, width: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
        widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    @discardableResult
    public func anchor(top: NSLayoutYAxisAnchor?,
                       leading: NSLayoutXAxisAnchor?,
                       bottom: NSLayoutYAxisAnchor?,
                       trailing: NSLayoutXAxisAnchor?,
                       padding: UIEdgeInsets = .zero,
                       size: CGSize = .zero) -> AnchoredConstraints {

        translatesAutoresizingMaskIntoConstraints = false
        var anchoredConstraints = AnchoredConstraints()

        if let top = top {
            anchoredConstraints.top = topAnchor.constraint(equalTo: top, constant: padding.top)
        }

        if let leading = leading {
            anchoredConstraints.leading = leadingAnchor.constraint(equalTo: leading, constant: padding.left)
        }

        if let bottom = bottom {
            anchoredConstraints.bottom = bottomAnchor.constraint(equalTo: bottom, constant: -padding.bottom)
        }

        if let trailing = trailing {
            anchoredConstraints.trailing = trailingAnchor.constraint(equalTo: trailing, constant: -padding.right)
        }

        if size.width != 0 {
            anchoredConstraints.width = widthAnchor.constraint(equalToConstant: size.width)
        }

        if size.height != 0 {
            anchoredConstraints.height = heightAnchor.constraint(equalToConstant: size.height)
        }

        [anchoredConstraints.top, anchoredConstraints.leading, anchoredConstraints.bottom, anchoredConstraints.trailing, anchoredConstraints.width, anchoredConstraints.height].forEach { $0?.isActive = true }

        return anchoredConstraints
    }

    @discardableResult
    public func fillSuperview(padding: UIEdgeInsets = .zero) -> AnchoredConstraints {
        translatesAutoresizingMaskIntoConstraints = false
        let anchoredConstraints = AnchoredConstraints()
        guard let superviewTopAnchor = superview?.topAnchor,
              let superviewBottomAnchor = superview?.bottomAnchor,
              let superviewLeadingAnchor = superview?.leadingAnchor,
              let superviewTrailingAnchor = superview?.trailingAnchor else {
            return anchoredConstraints
        }

        return anchor(top: superviewTopAnchor, leading: superviewLeadingAnchor, bottom: superviewBottomAnchor, trailing: superviewTrailingAnchor, padding: padding)
    }

    @discardableResult
    public func fillSuperviewSafeAreaLayoutGuide(padding: UIEdgeInsets = .zero) -> AnchoredConstraints {
        let anchoredConstraints = AnchoredConstraints()
        guard let superviewTopAnchor = superview?.safeAreaLayoutGuide.topAnchor,
              let superviewBottomAnchor = superview?.safeAreaLayoutGuide.bottomAnchor,
              let superviewLeadingAnchor = superview?.safeAreaLayoutGuide.leadingAnchor,
              let superviewTrailingAnchor = superview?.safeAreaLayoutGuide.trailingAnchor else {
            return anchoredConstraints
        }
        return anchor(top: superviewTopAnchor, leading: superviewLeadingAnchor, bottom: superviewBottomAnchor, trailing: superviewTrailingAnchor, padding: padding)
    }

    public func centerInSuperview(size: CGSize = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        if let superviewCenterXAnchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: superviewCenterXAnchor).isActive = true
        }

        if let superviewCenterYAnchor = superview?.centerYAnchor {
            centerYAnchor.constraint(equalTo: superviewCenterYAnchor).isActive = true
        }

        if size.width != 0 {
            widthAnchor.constraint(equalToConstant: size.width).isActive = true
        }

        if size.height != 0 {
            heightAnchor.constraint(equalToConstant: size.height).isActive = true
        }
    }

    public func centerXToSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        if let superviewCenterXAnchor = superview?.centerXAnchor {
            centerXAnchor.constraint(equalTo: superviewCenterXAnchor).isActive = true
        }
    }

    public func centerYToSuperview() {
        translatesAutoresizingMaskIntoConstraints = false
        if let superviewCenterYAnchor = superview?.centerYAnchor {
            centerYAnchor.constraint(equalTo: superviewCenterYAnchor).isActive = true
        }
    }

    @discardableResult
    public func constrainHeight(_ constant: CGFloat) -> AnchoredConstraints {
        translatesAutoresizingMaskIntoConstraints = false
        var anchoredConstraints = AnchoredConstraints()
        anchoredConstraints.height = heightAnchor.constraint(equalToConstant: constant)
        anchoredConstraints.height?.isActive = true
        return anchoredConstraints
    }

    @discardableResult
    public func constrainWidth(_ constant: CGFloat) -> AnchoredConstraints {
        translatesAutoresizingMaskIntoConstraints = false
        var anchoredConstraints = AnchoredConstraints()
        anchoredConstraints.width = widthAnchor.constraint(equalToConstant: constant)
        anchoredConstraints.width?.isActive = true
        return anchoredConstraints
    }

    public func setupShadow(opacity: Float = 0, radius: CGFloat = 0, offset: CGSize = .zero, color: UIColor = .black) {
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
    }

    convenience public init(backgroundColor: UIColor = .clear) {
        self.init(frame: .zero)
        self.backgroundColor = backgroundColor
    }

    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

    func clearConstraints() {
        for subview in self.subviews {
            subview.clearConstraints()
        }
        self.removeConstraints(self.constraints)
    }
}
