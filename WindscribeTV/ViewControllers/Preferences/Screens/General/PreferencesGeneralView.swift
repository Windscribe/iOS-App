//
//  PreferencesGeneralView.swift
//  WindscribeTV
//
//  Created by Andre Fonseca on 02/08/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

class PreferencesGeneralView: UIView {
    lazy var languagesView: TopSettingSection = {
        TopSettingSection.fromNib()
    }()
    lazy var orderByView: SettingsSection = {
        SettingsSection.fromNib()
    }()

    @IBOutlet weak var contentStackView: UIStackView!

    var viewModel: GeneralViewModelType!
    private let disposeBag = DisposeBag()

    func setup() {
        languagesView.populate(with: TextsAsset.General.languages, title: GeneralHelper.getTitle(.language))
        orderByView.populate(with: TextsAsset.orderPreferences, title: GeneralHelper.getTitle(.locationOrder))

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
        languagesView.updateText(with: TextsAsset.General.languages, title: GeneralHelper.getTitle(.language))
        orderByView.updateText(with: TextsAsset.orderPreferences, title: GeneralHelper.getTitle(.locationOrder))
    }

    private func bindViews() {
        viewModel.languageUpdatedTrigger.subscribe { _ in
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
