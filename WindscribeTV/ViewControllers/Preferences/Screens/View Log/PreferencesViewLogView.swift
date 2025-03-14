//
//  PreferencesViewLogView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 09/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class PreferencesViewLogView: UIView {
    let disposeBag = DisposeBag()
    var viewModel: ViewLogViewModel!

    @IBOutlet var textView: UITextView!

    func setup(with viewModel: ViewLogViewModel) {
        self.viewModel = viewModel
        bindViews()

        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.showsVerticalScrollIndicator = true
        textView.panGestureRecognizer.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirect.rawValue)]
        textView.textColor = .white.withAlphaComponent(0.5)
    }

    func scrolltoBottom() {
        textView.scrollToBottom()
    }

    private func bindViews() {
        viewModel.logContent.subscribe(onNext: { [weak self] content in
            guard let self = self else { return }
            self.textView.text = content
            self.scrolltoBottom()
        }, onError: { _ in })
            .disposed(by: disposeBag)
    }
}
