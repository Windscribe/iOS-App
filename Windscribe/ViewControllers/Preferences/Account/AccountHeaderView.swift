//
//	AccountHeaderView.swift
//	Windscribe
//
//	Created by Thomas on 21/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

class AccountHeaderView: UIView {
    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setLetterSpacing(value: 3.0)
        label.textAlignment = .right
        label.layer.opacity = 0.5
        label.font = UIFont.bold(size: 12)
        return label
    }()

    private let disposeBag = DisposeBag()

    init(isDarkMode: BehaviorSubject<Bool>) {
        super.init(frame: .zero)

        addSubview(label)
        label.makeTopAnchor(constant: 16)
        label.makeLeadingAnchor(constant: 16)
        label.makeBottomAnchor(constant: 16)
        bindViews(isDarkMode: isDarkMode)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func bindViews(isDarkMode: BehaviorSubject<Bool>) {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.label.textColor = ThemeUtils.primaryTextColor(isDarkMode: $0)
        }).disposed(by: disposeBag)
    }
}
