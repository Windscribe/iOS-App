//
//  ListSelectionViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation

enum CardHeaderButtonType {
    case all
    case fav
    case staticIP
    case config
    case startSearch
}

protocol ListSelectionViewDelegate: AnyObject {
    func cardHeaderWasSelected(with type: CardHeaderButtonType)
}

protocol ListSelectionViewModelType {
    var delegate: ListSelectionViewDelegate? { get set }
    var isActive: CurrentValueSubject<Bool, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var selectedAction: CurrentValueSubject<CardHeaderButtonType, Never> { get }

    func setActive()
    func allSelected()
    func favSelected()
    func staticSelected()
    func configSelected()
    func startSearchSelected()
    func setSelectedAction(selectedAction: CardHeaderButtonType)
}

class ListSelectionViewModel: ListSelectionViewModelType {
    weak var delegate: ListSelectionViewDelegate?
    var isActive = CurrentValueSubject<Bool, Never>(true)
    var isDarkMode: CurrentValueSubject<Bool, Never>
    var selectedAction = CurrentValueSubject<CardHeaderButtonType, Never>(.all)

    init (lookAndFeelRepository: LookAndFeelRepositoryType) {
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
    }

    func setSelectedAction(selectedAction: CardHeaderButtonType) {
        self.selectedAction.send(selectedAction)
    }

    func allSelected() {
        newActionSelected(selectedAction: .all)
    }

    func favSelected() {
        newActionSelected(selectedAction: .fav)
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
        isActive.send(true)
    }

    private func toggleActive() {
        let isActive = isActive.value
        self.isActive.send(!isActive)
    }

    private func newActionSelected(selectedAction: CardHeaderButtonType) {
        delegate?.cardHeaderWasSelected(with: selectedAction)
        self.selectedAction.send(selectedAction)
    }
}
