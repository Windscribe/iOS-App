//
//  SearchLocationsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol SearchCountryViewDelegate: AnyObject {
    func searchLocationUpdated(with text: String)
    func showSearchLocation()
    func dismissSearchLocation()
}

protocol SearchLocationsViewModelType {
    var isSearchActive: BehaviorSubject<Bool> { get }

    var delegate: SearchCountryViewDelegate? { get set }

    func searchTextFieldDidChange(text: String)
    func toggleSearch()

    func isActive() -> Bool
    func dismiss()
}

class SearchLocationsViewModel: SearchLocationsViewModelType {
    var isSearchActive = BehaviorSubject<Bool>(value: false)

    weak var delegate: SearchCountryViewDelegate?

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
