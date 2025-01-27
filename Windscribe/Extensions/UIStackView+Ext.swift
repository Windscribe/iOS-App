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
}
