//
//  WSFillLayoutView.swift
//  Windscribe
//
//  Created by Thomas on 18/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import UIKit

public class WSFillLayoutView: UIView {
    public lazy var rootStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    public lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    public lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    public lazy var scrollView = UIScrollView()

    public init() {
        super.init(frame: .zero)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        addSubview(rootStackView)
        rootStackView.fillSuperview()

        rootStackView.addArrangedSubviews([
            scrollView,
            bottomStackView,
        ])
        scrollView.widthAnchor.constraint(equalTo: rootStackView.widthAnchor).isActive = true

        scrollView.addSubview(stackView)
        stackView.fillSuperview()
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        scrollView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
    }
}
