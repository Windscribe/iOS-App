//
//  ServerInfoView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol ServerInfoViewModelType {
    var serverCountSubject: PublishSubject<Int> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
}

class ServerInfoViewModel: ServerInfoViewModelType {
    let serverCountSubject = PublishSubject<Int>()
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)
    let disposeBag = DisposeBag()

    init(localDatabase: LocalDatabase, themeManager: ThemeManager) {
        localDatabase.getServersObservable().subscribe {
            self.serverCountSubject.onNext($0.count)
        }.disposed(by: disposeBag)

        themeManager.darkTheme.subscribe { data in
            self.isDarkMode.onNext(data)
        }.disposed(by: disposeBag)
    }
}

class ServerInfoView: UIView {
    let disposeBag = DisposeBag()

    var infoLabel = UILabel()

    var viewModel: ServerInfoViewModelType! {
        didSet {
            bindViewModel()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        addViews()
        setLayout()
    }

    private func bindViewModel() {
        viewModel.serverCountSubject.observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: {
                self.infoLabel.text = "\(TextsAsset.allServers) (\($0))"
            }).disposed(by: disposeBag)

        viewModel.isDarkMode.subscribe { isDarkMode in
            self.updateLayourForTheme(isDarkMode: isDarkMode)
        }.disposed(by: disposeBag)
    }

    private func updateLayourForTheme(isDarkMode: Bool) {
        backgroundColor = isDarkMode ? .nightBlue : .white
        infoLabel.textColor = isDarkMode ? UIColor.whiteWithOpacity(opacity: 0.7) : .nightBlue
    }

    private func addViews() {
        backgroundColor = .clear
        infoLabel.font = UIFont.regular(size: 12)

        addSubview(infoLabel)
    }

    private func setLayout() {
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // infoView
            widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            heightAnchor.constraint(equalToConstant: 40),

            // infoLabel
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 5),
            infoLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            infoLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        ])
    }
}
