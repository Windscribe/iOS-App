//
//  ViewLogViewController.swift
//  Windscribe
//
//  Created by Yalcin on 2019-07-11.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

class ViewLogViewController: WSNavigationViewController {
    var logView: UITextView!
    var logger: FileLogger?
    lazy var lookAndFeelRepository = Assembler.resolve(LookAndFeelRepositoryType.self)
    var viewModel: ViewLogViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        logger?.logD(self, "Displaying Debug View")
        addViews()
        addAutoLayoutConstraints()
        setupLongPressGesture()
        bindViews()
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        addAutoLayoutConstraints()
    }

    private func bindViews() {
        titleLabel.text = viewModel?.title
        viewModel.logContent.subscribe(onNext: { content in
            self.logView.text = content
            self.logView.scrollToBottom()
        }, onError: { _ in })
            .disposed(by: disposeBag)
        viewModel.showProgress.subscribe(onNext: { [weak self] show in
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

    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        logView.addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress() {
        UIPasteboard.general.string = logView.text
        showAlert()
    }

    private func showAlert() {
        let alert = UIAlertController(title: "Copied!", message: "Log copied to clipboard", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
