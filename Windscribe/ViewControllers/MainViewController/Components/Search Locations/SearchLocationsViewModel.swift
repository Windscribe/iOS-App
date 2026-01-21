//
//  SearchLocationsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation

protocol SearchCountryViewDelegate: AnyObject {
    func searchLocationUpdated(with text: String)
    func showSearchLocation()
    func dismissSearchLocation()
}

protocol SearchLocationsViewModelType {
    var isSearchActive: CurrentValueSubject<Bool, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var refreshLanguage: PassthroughSubject<Void, Never> { get }

    var delegate: SearchCountryViewDelegate? { get set }

    func searchTextFieldDidChange(text: String)
    func toggleSearch()

    func isActive() -> Bool
    func dismiss()
}

class SearchLocationsViewModel: SearchLocationsViewModelType {
    let isSearchActive = CurrentValueSubject<Bool, Never>(false)
    let refreshLanguage = PassthroughSubject<Void, Never>()

    let isDarkMode: CurrentValueSubject<Bool, Never>
    private var cancellables = Set<AnyCancellable>()

    weak var delegate: SearchCountryViewDelegate?

    init(lookAndFeelRepository: LookAndFeelRepositoryType, languageManager: LanguageManager) {
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        languageManager.activelanguage.sink { [weak self] _ in self?.refreshLanguage.send(()) }
            .store(in: &cancellables)
    }

    func toggleSearch() {
        let isSearchActive = isSearchActive.value
        if isSearchActive {
            delegate?.searchLocationUpdated(with: "")
            delegate?.dismissSearchLocation()
        } else {
            delegate?.showSearchLocation()
        }
        self.isSearchActive.send(!isSearchActive)
    }

    func isActive() -> Bool {
        return isSearchActive.value
    }

    func dismiss() {
        if isSearchActive.value {
            toggleSearch()
        }
    }

    func searchTextFieldDidChange(text: String) {
        delegate?.searchLocationUpdated(with: text)
    }
}
