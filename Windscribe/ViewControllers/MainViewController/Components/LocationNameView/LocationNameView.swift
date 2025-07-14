//
//  nickNameView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

class LocationNameView: UIView {

    private let spacerView = UIView()

    private let mainNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.bold(size: 26)
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let nickNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.regular(size: 26)
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    private var stackView: UIStackView = UIStackView()

    private lazy var heightConstraint: NSLayoutConstraint = {
        return stackView.heightAnchor.constraint(equalToConstant: 68)
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup
    private func setupUI() {
        spacerView.isHidden = true

        stackView.addArrangedSubviews([spacerView, mainNameLabel, nickNameLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .bottom
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }

    // MARK: - Public Methods
    func update(mainName: String?, nickName: String?) {
        mainNameLabel.text = mainName
        nickNameLabel.text = nickName

        layoutIfNeeded()

        let mainNameWidth = mainNameLabel.intrinsicContentSize.width
        let nickNameWidth = nickNameLabel.intrinsicContentSize.width
        let spacing = stackView.spacing
        let availableWidth = bounds.width

        if mainNameWidth + nickNameWidth + spacing > availableWidth && availableWidth > 0 {
            stackView.axis = .vertical
            stackView.alignment = .leading
            stackView.spacing = 0
            heightConstraint.constant = 88
            nickNameLabel.font = UIFont.regular(size: 21)
            spacerView.isHidden = false
        } else {
            stackView.axis = .horizontal
            stackView.alignment = .bottom
            stackView.spacing = 8
            heightConstraint.constant = 68
            nickNameLabel.font = UIFont.regular(size: 26)
            spacerView.isHidden = true
        }

        layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Recheck layout when bounds change
        if !mainNameLabel.text.isNilOrEmpty || !nickNameLabel.text.isNilOrEmpty {
            update(mainName: mainNameLabel.text, nickName: nickNameLabel.text)
        }
    }
}

// MARK: - Helper Extension
private extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}
