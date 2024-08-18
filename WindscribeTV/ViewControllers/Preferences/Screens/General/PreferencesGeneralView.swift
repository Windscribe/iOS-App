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
    var viewModel: GeneralViewModelType!

    lazy var languagesView: SettingsSection = {
        SettingsSection.fromNib()
    }()
    lazy var orderByView: SettingsSection = {
        SettingsSection.fromNib()
    }()

    @IBOutlet weak var contentStackView: UIStackView!

    func setup() {
        languagesView.populate(with: TextsAsset.General.languages, title: GeneralHelper.getTitle(.language))
        languagesView.delegate = self
        orderByView.populate(with: TextsAsset.orderPreferences, title: GeneralHelper.getTitle(.locationOrder))
        orderByView.select(option: viewModel.getCurrentLocationOrder())
        orderByView.delegate = self
        
        contentStackView.addArrangedSubview(languagesView)
        contentStackView.addArrangedSubview(orderByView)
        contentStackView.addArrangedSubview(UIView())
    }
    
    func updateSelection() {
        languagesView.select(option: viewModel.getCurrentLanguage(), animated: false)
        orderByView.select(option: viewModel.getCurrentLocationOrder(), animated: false)
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
