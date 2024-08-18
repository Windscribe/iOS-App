//
//  ViewLogViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-07-11.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

class ViewLogViewController: WSNavigationViewController {
    var logView: UITextView!
    var logger: FileLogger?
    lazy var themeManager = Assembler.resolve(ThemeManager.self)
    var viewModel: ViewLogViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger?.logD(self, "Displaying Debug View")
        addViews()
        addAutoLayoutConstraints()
        bindViews()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.addAutoLayoutConstraints()
    }

    private func bindViews() {
        titleLabel.text = viewModel?.title
        viewModel.logContent.subscribe(onNext: { content in
            self.logView.text = content
            self.logView.scrollToBottom()
        }, onError: { _ in })
        .disposed(by: disposeBag)
        viewModel.showProgress.subscribe(onNext: { [weak self]show in
            if show {
                self?.showLoading()
            } else {
                self?.endLoading()
            }
        }, onError: { _ in })
        .disposed(by: disposeBag)
        viewModel.isDarkMode.subscribe(onNext: { [self] isDark in
            self.logView.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDark)
            self.setupViews(isDark: isDark)
        }).disposed(by: disposeBag)
    }
}
