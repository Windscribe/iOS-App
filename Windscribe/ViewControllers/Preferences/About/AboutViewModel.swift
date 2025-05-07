//
//	AboutViewModel.swift
//	Windscribe
//
//	Created by Thomas on 20/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol AboutViewModelType {
    var isDarkMode: BehaviorSubject<Bool> { get }
    func numberOfRowsInSection() -> Int
    func celldata(at indexPath: IndexPath) -> AboutItemCell
}

class AboutViewModel: AboutViewModelType {
    // MARK: - Dependencies

    let preferences: Preferences
    let lookAndFeelRepo: LookAndFeelRepositoryType

    let disposeBag = DisposeBag()
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)
    var items = [AboutItemCell]()

    init(lookAndFeelRepo: LookAndFeelRepositoryType, preference: Preferences) {
        self.lookAndFeelRepo = lookAndFeelRepo
        preferences = preference
        items = [.status, .aboutUs, .privacyPolicy, .terms, .blog, .jobs, .softwareLicenses, .changelog]
        load()
    }

    private func load() {
        preferences.getDarkMode().subscribe { data in
            self.isDarkMode.onNext(data ?? DefaultValues.darkMode)
        }.disposed(by: disposeBag)
    }

    func numberOfRowsInSection() -> Int {
        return items.count
    }

    func celldata(at indexPath: IndexPath) -> AboutItemCell {
        return items[indexPath.row]
    }
}
