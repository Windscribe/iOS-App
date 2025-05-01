//
//  AdvanceParamsViewController.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-12.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

class AdvanceParamsViewController: WSNavigationViewController {
    // MARK: - Properties

    var viewModel: AdvanceParamsViewModel?

    // MARK: - UI elements

    private lazy var inputBox: UITextView = {
        let textfield = UITextView()
        textfield.constrainHeight(200)
        textfield.makeCorner(16)
        textfield.font = .text(size: 12)
        textfield.textAlignment = .justified
        textfield.isEditable = true
        textfield.spellCheckingType = .no
        textfield.contentInset = UIEdgeInsets(horizontalInset: 12.0, verticalInset: 8.0)
        return textfield
    }()

    private lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.addTarget(self, action: #selector(saveButtonTap), for: .touchUpInside)
        btn.anchor(height: 48)
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        btn.setTitleColor(UIColor.midnight, for: .normal)
        btn.backgroundColor = UIColor.seaGreen
        btn.setTitle(TextsAsset.save, for: .normal)
        return btn
    }()

    // MARK: - View setup and Binding

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBinding()
    }

    private func setupUI() {
        setupFillLayoutView()
        layoutView.stackView.addArrangedSubviews([
            inputBox,
            saveButton
        ])
        layoutView.stackView.spacing = 16
        let paddingTop = UIScreen.hasTopNotch ? 48.0 : 16.0
        layoutView.stackView.setPadding(UIEdgeInsets(top: paddingTop, left: 24, bottom: 16, right: 24))
    }

    private func setupBinding() {
        guard let viewModel = viewModel else { return }
        viewModel.isDarkMode.subscribe { isDarkMode in
            self.setupViews(isDark: isDarkMode)
            self.inputBox.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
            self.inputBox.backgroundColor = ThemeUtils.getVersionBorderColor(isDarkMode: isDarkMode)
            self.view.backgroundColor = ThemeUtils.backgroundColor(isDarkMode: isDarkMode)
            self.backButton.setImage(UIImage(named: ThemeUtils.backButtonAsset(isDarkMode: isDarkMode)), for: .normal)
            self.closeButton?.setImage(UIImage(named: ThemeUtils.closeButtonAsset(isDarkMode: isDarkMode)), for: .normal)
        }.disposed(by: disposeBag)
        inputBox.rx.text.distinctUntilChanged().skip(1).subscribe(onNext: { string in
            self.viewModel?.onAdvanceParamsTextChange(text: string)
        }).disposed(by: disposeBag)
        viewModel.advanceParams.distinctUntilChanged().subscribe(onNext: { params in
            DispatchQueue.main.async { [weak self] in
                self?.inputBox.text = params
            }
        }).disposed(by: disposeBag)
        viewModel.titleText.subscribe(onNext: { title in
            DispatchQueue.main.async { [weak self] in
                self?.titleLabel.text = title
            }
        }).disposed(by: disposeBag)
        viewModel.showProgressBar.subscribe(onNext: { show in
            DispatchQueue.main.async { [weak self] in
                if show {
                    self?.showLoading()
                } else {
                    self?.endLoading()
                }
            }
        }).disposed(by: disposeBag)

        Observable.combineLatest(viewModel.showError.distinctUntilChanged().asObservable(), viewModel.isDarkMode.asObservable()).bind { show, isDarkMode in
            DispatchQueue.main.async {
                if show {
                    self.inputBox.textColor = UIColor.red
                } else {
                    self.inputBox.textColor = ThemeUtils.primaryTextColor(isDarkMode: isDarkMode)
                }
            }
        }.disposed(by: disposeBag)
    }

    // MARK: - Actions

    @objc func saveButtonTap() {
        inputBox.endEditing(true)
        viewModel?.saveButtonTap()
    }
}
