//
//  WSRefreshControl.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-07.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Combine
import RxSwift
import Swinject
import UIKit

class WSRefreshControl: UIRefreshControl {
    var disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    var backView: RefreshControlBackView! {
        didSet {
            subviews[0].addSubview(backView)
        }
    }

    init(isDarkMode: CurrentValueSubject<Bool, Never>) {
        super.init()
        setText(TextsAsset.refreshLatency)
        layer.opacity = 0.5
        tintColor = .white
        backgroundColor = .nightBlue
        bindViews(isDarkMode: isDarkMode)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setText(_ text: String, size: CGFloat = 12) {
        let color = tintColor ?? UIColor.white
        let myAttribute = [NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.font: UIFont.bold(size: size)]
        let myAttrString = NSAttributedString(string: text, attributes: myAttribute)
        attributedTitle = myAttrString
    }

    func resetText() {
        setText(TextsAsset.refreshLatency)
    }

    private func bindViews(isDarkMode: CurrentValueSubject<Bool, Never>) {
        isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.updateDarkMode(isDarkMode: isDark)
            }
            .store(in: &cancellables)
    }

    private func updateDarkMode(isDarkMode: Bool) {
        guard backView != nil else {
            disposeBag = DisposeBag()
            return
        }
        tintColor = .from(.iconColor, isDarkMode)
        backgroundColor = .from(.backgroundColor, isDarkMode)
        backView.label.backgroundColor = UIColor.clear
        backView.label.textColor = .from(.textColor, isDarkMode)
        setText(attributedTitle?.string ?? TextsAsset.refreshLatency)
    }
}
