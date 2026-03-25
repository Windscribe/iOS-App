//
//  ListHeaderView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import UIKit

enum ListHeaderViewType {
    case staticIP, customConfig, favorites, empty

    var description: String {
        switch self {
        case .staticIP:
            return TextsAsset.staticIPList
        case .customConfig:
            return TextsAsset.customConfigs
        case .favorites:
            return TextsAsset.favoriteNodes
        case .empty:
            return ""
        }
    }
}

protocol ListHeaderViewModelType {
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var type: CurrentValueSubject<ListHeaderViewType, Never> { get }
    var refreshLanguage: PassthroughSubject<Void, Never> { get }
    func updateType(with type: ListHeaderViewType)
}

class ListHeaderViewModel: ListHeaderViewModelType {
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let type = CurrentValueSubject<ListHeaderViewType, Never>(.empty)
    let refreshLanguage = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    init(lookAndFeelRepository: LookAndFeelRepositoryType, languageManager: LanguageManager) {
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        languageManager.activelanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshLanguage.send(())
            }
            .store(in: &cancellables)
    }

    func updateType(with type: ListHeaderViewType) {
        self.type.send(type)
    }
}

class ListHeaderView: UIView {
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
        viewModel.type
            .receive(on: DispatchQueue.main)
            .sink {
                self.infoLabel.text = $0.description
            }
            .store(in: &cancellables)

        viewModel.isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDarkMode in
                self?.updateLayourForTheme(isDarkMode: isDarkMode)
            }
            .store(in: &cancellables)

        viewModel.refreshLanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.infoLabel.text = viewModel.type.value.description
            }
            .store(in: &cancellables)
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
            widthAnchor.constraint(equalTo: widthAnchor),
            heightAnchor.constraint(equalToConstant: 40),

            // infoLabel
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 5),
            infoLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            infoLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -16)
        ])
    }
}
