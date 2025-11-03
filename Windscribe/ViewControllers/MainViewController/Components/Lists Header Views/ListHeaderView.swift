//
//  ListHeaderView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import UIKit
import RxSwift

enum ListHeaderViewType {
    case staticIP, customConfig, favNodes, empty

    var description: String {
        switch self {
        case .staticIP:
            return TextsAsset.staticIPList
        case .customConfig:
            return TextsAsset.customConfigs
        case .favNodes:
            return TextsAsset.favoriteNodes
        case .empty:
            return ""
        }
    }
}

protocol ListHeaderViewModelType {
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var type: BehaviorSubject<ListHeaderViewType> { get }
    var refreshLanguage: PublishSubject<Void> { get }
    func updateType(with type: ListHeaderViewType)
}

class ListHeaderViewModel: ListHeaderViewModelType {
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let type = BehaviorSubject<ListHeaderViewType>(value: .empty)
    let refreshLanguage = PublishSubject<Void>()
    private var cancellables = Set<AnyCancellable>()

    init(lookAndFeelRepository: LookAndFeelRepositoryType, languageManager: LanguageManager) {
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        languageManager.activelanguage.sink { _ in self.refreshLanguage.onNext(()) }
            .store(in: &cancellables)
    }

    func updateType(with type: ListHeaderViewType) {
        self.type.onNext(type)
    }
}

class ListHeaderView: UIView {
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    let infoLabel = UILabel()

    var viewModel: ListHeaderViewModelType! {
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
        viewModel.type.observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: {
                self.infoLabel.text = $0.description
            }).disposed(by: disposeBag)

        viewModel.isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { isDarkMode in
                self.updateLayourForTheme(isDarkMode: isDarkMode)
            }
            .store(in: &cancellables)

        viewModel.refreshLanguage.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if let type = try? viewModel.type.value() {
                self.infoLabel.text = type.description
            }
        }).disposed(by: disposeBag)
    }

    private func updateLayourForTheme(isDarkMode: Bool) {
        backgroundColor = .from(.backgroundColor, isDarkMode)
        infoLabel.textColor = .from(.infoColor, isDarkMode)
    }

    private func addViews() {
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
