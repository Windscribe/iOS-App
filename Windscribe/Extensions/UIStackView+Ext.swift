import UIKit

extension UIStackView {
    public func removeAllArrangedSubviews() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    public func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }
    public func setPadding(_ inset: UIEdgeInsets) {
        layoutMargins = inset
        isLayoutMarginsRelativeArrangement = true
    }
}
