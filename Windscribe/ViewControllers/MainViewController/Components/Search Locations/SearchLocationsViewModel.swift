//
//  SearchLocationsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation
import RxSwift

protocol SearchCountryViewDelegate: AnyObject {
    func searchLocationUpdated(with text: String)
    func showSearchLocation()
    func dismissSearchLocation()
}

protocol SearchLocationsViewModelType {
    var isSearchActive: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var refreshLanguage: PublishSubject<Void> { get }

    var delegate: SearchCountryViewDelegate? { get set }

    func searchTextFieldDidChange(text: String)
    func toggleSearch()

    func isActive() -> Bool
    func dismiss()
}

class SearchLocationsViewModel: SearchLocationsViewModelType {
    let isSearchActive = BehaviorSubject<Bool>(value: false)
    let refreshLanguage = PublishSubject<Void>()

    let isDarkMode: BehaviorSubject<Bool>
    private var cancellables = Set<AnyCancellable>()

    weak var delegate: SearchCountryViewDelegate?

    init(lookAndFeelRepository: LookAndFeelRepositoryType, languageManager: LanguageManager) {
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        languageManager.activelanguage.sink { _ in self.refreshLanguage.onNext(()) }
            .store(in: &cancellables)
    }

    func toggleSearch() {
        let isSearchActive = (try? isSearchActive.value()) ?? false
        if isSearchActive {
            delegate?.searchLocationUpdated(with: "")
            delegate?.dismissSearchLocation()
        } else {
            delegate?.showSearchLocation()
        }
        self.isSearchActive.onNext(!isSearchActive)
    }

    func isActive() -> Bool {
        return (try? isSearchActive.value()) ?? false
    }

    func dismiss() {
        if (try? isSearchActive.value()) ?? false {
            toggleSearch()
        }
    }

    func searchTextFieldDidChange(text: String) {
        delegate?.searchLocationUpdated(with: text)
    }
}
