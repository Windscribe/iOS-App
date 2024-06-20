//
//  CheckView.swift
//  Windscribe
//
//  Created by Thomas on 13/09/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class CheckView: UIStackView {
    var isDarkMode: BehaviorSubject<Bool>
    let disposeBag = DisposeBag()

    private(set) var content: String

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .text(size: 16)
        label.numberOfLines = 0
        label.text = content
        return label
    }()

    private lazy var stepView: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(named: ImagesAsset.CheckMarkButton.on)
        img.anchor(width: 12, height: 12)
        img.contentMode = .scaleAspectFit
        return img
    }()

    init(content: String, isDarkMode: BehaviorSubject<Bool>) {
        self.content = content
        self.isDarkMode = isDarkMode
        super.init(frame: .zero)
        setup()
        bindViews()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func setup() {
        addSubview(stepView)
        addArrangedSubview(titleLabel)
        setPadding(UIEdgeInsets(top: 8, left: 24, bottom: 8, right: 0))
        stepView.anchor(
            top: topAnchor,
            left: leftAnchor,
            paddingTop: 12,
            paddingLeft: 0
        )
    }

    func updateContent(_ content: String) {
        self.content = content
        titleLabel.text = content
    }

    private func bindViews() {
        isDarkMode.subscribe(on: MainScheduler.instance).subscribe( onNext: {
            self.titleLabel.textColor = ThemeUtils.primaryTextColor50(isDarkMode: $0)
        }).disposed(by: self.disposeBag)
    }
}
