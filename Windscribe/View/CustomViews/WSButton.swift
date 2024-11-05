//
//  WSButton.swift
//  Windscribe
//
//  Created by Thomas on 30/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

enum WSButtonType {
    case hightlight
    case normal
}

enum WSButtonSize {
    case small
    case medium
    case large
}

class WSButton: UIButton {
    private(set) var type: WSButtonType
    private(set) var size: WSButtonSize
    private(set) var text: String
    private let disposeBag = DisposeBag()

    init(type: WSButtonType, size: WSButtonSize, text: String, isDarkMode: BehaviorSubject<Bool>) {
        self.type = type
        self.size = size
        self.text = text
        super.init(frame: .zero)
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: {
            self.setup(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }

    private func setup(isDarkMode: Bool) {
        var font: UIFont = .systemFont(ofSize: 16)
        var color: UIColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        switch type {
        case .hightlight:
            backgroundColor = .seaGreen
            font = .text(size: getFontSize())
            color = .midnight
        case .normal:
            backgroundColor = ThemeUtils.wrapperColor(isDarkMode: isDarkMode)
            font = .bold(size: getFontSize())
            color = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
        }
        let attributeString = NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key.foregroundColor: color,
                         .font: font]
        )
        setAttributedTitle(attributeString, for: .normal)
        makeHeightAnchor(equalTo: getButtonSize())
        layer.cornerRadius = getButtonSize() / 2
    }

    private func getFontSize() -> CGFloat {
        switch size {
        case .small:
            return 12
        case .medium:
            return 14
        case .large:
            return 16
        }
    }

    private func getButtonSize() -> CGFloat {
        switch size {
        case .small:
            return 24
        case .medium:
            return 36
        case .large:
            return 48
        }
    }
}
