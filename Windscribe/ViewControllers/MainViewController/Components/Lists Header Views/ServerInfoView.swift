//
//  ServerInfoView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/03/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import Combine

protocol ServerInfoViewModelType {
    var locationsCountSubject: PassthroughSubject<Int, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    func updateWithSearchCount(searchCount: Int)
}

class ServerInfoViewModel: ServerInfoViewModelType {
    let locationsCountSubject = PassthroughSubject<Int, Never>()
    let isDarkMode: CurrentValueSubject<Bool, Never>
    private var cancellables = Set<AnyCancellable>()
    private let languageManager: LanguageManager
    private let locationListRepository: LocationListRepository

    private var count = 0

    init(languageManager: LanguageManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         locationListRepository: LocationListRepository) {
        self.languageManager = languageManager
        self.locationListRepository = locationListRepository
        self.isDarkMode = lookAndFeelRepository.isDarkModeSubject

        locationListRepository.locationListSubject
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] locations in
                    guard let self = self else { return }
                    // Count total groups across all servers
                    self.count = locations.reduce(0) { $0 + $1.datacenters.count }
                    self.locationsCountSubject.send(self.count)
            })
            .store(in: &cancellables)

        languageManager.activelanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.locationsCountSubject.send(self.count)
            }
            .store(in: &cancellables)
    }

    func updateWithSearchCount(searchCount: Int) {
        if searchCount >= 0 {
            self.locationsCountSubject.send(searchCount)
        } else {
            let servers = locationListRepository.currentLocationModels
            // Count total groups across all servers
            let totalGroupCount = servers.reduce(0) { $0 + $1.datacenters.count }
            self.locationsCountSubject.send(totalGroupCount)
        }
    }
}

class ServerInfoView: UIView {
    private var cancellables = Set<AnyCancellable>()

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

    func updadeWithSearchResult(searchCount: Int) {
        viewModel.updateWithSearchCount(searchCount: searchCount)
    }

    private func bindViewModel() {
        viewModel.locationsCountSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.infoLabel.text = "\(TextsAsset.allServers) (\(count))"
            }
            .store(in: &cancellables)

        viewModel.isDarkMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDarkMode in
                self?.updateLayourForTheme(isDarkMode: isDarkMode)
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
