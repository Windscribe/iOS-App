//
//  PreferencesGeneralView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 02/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import UIKit

class PreferencesGeneralView: UIView {
    lazy var languagesView: TopSettingSection = .fromNib()

    lazy var orderByView: SettingsSection = .fromNib()

    @IBOutlet var contentStackView: UIStackView!

    var viewModel: GeneralViewModelType!
    private let disposeBag = DisposeBag()

    func setup() {
        languagesView.populate(with: TextsAsset.General.languages, title: GeneralViewType.language.title)
        orderByView.populate(with: TextsAsset.orderPreferences, title: GeneralViewType.locationOrder.title)

        languagesView.delegate = self
        orderByView.select(option: viewModel.getCurrentLocationOrder())
        orderByView.delegate = self

        contentStackView.addArrangedSubview(languagesView)
        contentStackView.addArrangedSubview(orderByView)
        contentStackView.addArrangedSubview(UIView())

        bindViews()
    }

    func updateSelection() {
        languagesView.select(option: viewModel.getCurrentLanguage(), animated: false)
        orderByView.select(option: viewModel.getCurrentLocationOrder().localize(), animated: false)
    }

    func getFocusItem(onTop: Bool) -> UIView? {
        if onTop {
            return languagesView
        }
        return orderByView
    }

    private func updateText() {
        languagesView.updateText(with: TextsAsset.General.languages, title:  GeneralViewType.language.title)
        orderByView.updateText(with: TextsAsset.orderPreferences, title: GeneralViewType.locationOrder.title)
    }

    private func bindViews() {
        viewModel.languageUpdatedTrigger.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.updateText()
        }.disposed(by: disposeBag)
    }
}

extension PreferencesGeneralView: SettingsSectionDelegate {
    func optionWasSelected(for view: SettingsSection, with value: String) {
        if view == languagesView {
            viewModel.selectLanguage(with: value)
            return
        }
        if view == orderByView {
            viewModel.didSelectedLocationOrder(value: value)
            return
        }
    }
}
