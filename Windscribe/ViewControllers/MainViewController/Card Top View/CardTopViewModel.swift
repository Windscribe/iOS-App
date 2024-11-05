//
//  CardTopViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

enum CardHeaderButtonType {
    case all
    case fav
    case flix
    case staticIP
    case config
    case startSearch
}

protocol CardHeaderContainerViewDelegate {
    func cardHeaderWasSelected(with type: CardHeaderButtonType)
}

protocol CardTopViewModelType {
    var delegate: CardHeaderContainerViewDelegate? { get set }
    var isActive: BehaviorSubject<Bool> { get }
    var selectedAction: BehaviorSubject<CardHeaderButtonType> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }

    func setActive()
    func allSelected()
    func favSelected()
    func flixSelected()
    func staticSelected()
    func configSelected()
    func startSearchSelected()
    func setSelectedAction(selectedAction: CardHeaderButtonType)
}

class CardTopViewModel: CardTopViewModelType {
    var delegate: CardHeaderContainerViewDelegate?
    var isActive = BehaviorSubject<Bool>(value: true)
    var selectedAction = BehaviorSubject<CardHeaderButtonType>(value: .all)

    var themeManager: ThemeManager

    let disposeBag = DisposeBag()
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)

    init(themeManager: ThemeManager) {
        self.themeManager = themeManager
        load()
    }

    func setSelectedAction(selectedAction: CardHeaderButtonType) {
        self.selectedAction.onNext(selectedAction)
    }

    func allSelected() {
        newActionSelected(selectedAction: .all)
    }

    func favSelected() {
        newActionSelected(selectedAction: .fav)
    }

    func flixSelected() {
        newActionSelected(selectedAction: .flix)
    }

    func staticSelected() {
        newActionSelected(selectedAction: .staticIP)
    }

    func configSelected() {
        newActionSelected(selectedAction: .config)
    }

    func startSearchSelected() {
        newActionSelected(selectedAction: .startSearch)
        toggleActive()
    }

    func setActive() {
        isActive.onNext(true)
    }

    private func load() {
        themeManager.darkTheme.subscribe { data in
            self.isDarkMode.onNext(data)
        }.disposed(by: disposeBag)
    }

    private func toggleActive() {
        let isActive = (try? isActive.value()) ?? true
        self.isActive.onNext(!isActive)
    }

    private func newActionSelected(selectedAction: CardHeaderButtonType) {
        delegate?.cardHeaderWasSelected(with: selectedAction)
        self.selectedAction.onNext(selectedAction)
    }
}
