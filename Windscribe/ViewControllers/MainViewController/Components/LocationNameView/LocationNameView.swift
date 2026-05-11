//
//  nickNameView.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import Combine

protocol LocationNameViewModel {
    var locationInfoUpdatedTrigger: PassthroughSubject<Bool, Never> { get }
    func getInfo() -> LocationUIInfo?
}

class LocationNameViewModelImpl: LocationNameViewModel {

    let locationInfoUpdatedTrigger = PassthroughSubject<Bool, Never>()

    private let languageManager: LanguageManager
    private let locationsManager: LocationsManager

    private var isConnected = false

    private var cancellables = Set<AnyCancellable>()

    init(languageManager: LanguageManager,
         vpnStateRepository: VPNStateRepository,
         locationsManager: LocationsManager) {
        self.languageManager = languageManager
        self.locationsManager = locationsManager

        self.locationInfoUpdatedTrigger.send(isConnected)

        locationsManager.selectedLocationUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
            guard let self = self else { return }
                self.locationInfoUpdatedTrigger.send(isConnected)
        }.store(in: &cancellables)

        locationsManager.bestLocationUpdatedTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
            guard let self = self else { return }
                self.locationInfoUpdatedTrigger.send(isConnected)
        }.store(in: &cancellables)

        languageManager.activelanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
            guard let self = self else { return }
                self.locationInfoUpdatedTrigger.send(isConnected)
        }.store(in: &cancellables)

        vpnStateRepository.getStatus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.isConnected = state == .connected
                self.locationInfoUpdatedTrigger.send(self.isConnected)
            }
            .store(in: &cancellables)
    }

    func getInfo() -> LocationUIInfo? {
        locationsManager.getLocationUIInfo()
    }
}

class LocationNameView: UIView {

    private var cancellables = Set<AnyCancellable>()
    private let spacerView = UIView()
    private let horizontalSpacing: CGFloat = 8
    private let verticalSpacing: CGFloat = 0

    private let mainNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.bold(size: 26)
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let nickNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.regular(size: 26)
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    private var stackView: UIStackView = UIStackView()

    private lazy var heightConstraint: NSLayoutConstraint = {
        return stackView.heightAnchor.constraint(equalToConstant: 68)
    }()

    var viewModel: LocationNameViewModel! {
        didSet {
            bindViewModel()
        }
    }

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func bindViewModel() {
        viewModel.locationInfoUpdatedTrigger
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                guard let self = self, let info = self.viewModel.getInfo() else { return }
                // If it's connected and the name has best location then don't change
                guard !(isConnected && info.cityName.contains(TextsAsset.bestLocation)) else { return }
                self.update(mainName: info.cityName, nickName: info.nickName)
        }.store(in: &cancellables)
    }

    // MARK: - Setup
    private func setupUI() {
        spacerView.isHidden = true

        stackView.addArrangedSubviews([spacerView, mainNameLabel, nickNameLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .bottom
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint
        ])
    }

    private func update(mainName: String?, nickName: String?) {
        mainNameLabel.text = mainName
        nickNameLabel.text = nickName
        nickNameLabel.font = UIFont.regular(size: 26)

        layoutIfNeeded()

        let mainNameWidth = mainNameLabel.intrinsicContentSize.width
        let nickNameWidth = nickNameLabel.intrinsicContentSize.width
        let availableWidth = bounds.width

        if mainNameWidth + nickNameWidth + horizontalSpacing > availableWidth && availableWidth > 0 {
            stackView.axis = .vertical
            stackView.alignment = .leading
            stackView.spacing = verticalSpacing
            heightConstraint.constant = 88
            nickNameLabel.font = UIFont.regular(size: 21)
            spacerView.isHidden = false
        } else {
            stackView.axis = .horizontal
            stackView.alignment = .bottom
            stackView.spacing = horizontalSpacing
            heightConstraint.constant = 68
            nickNameLabel.font = UIFont.regular(size: 26)
            spacerView.isHidden = true
        }

        layoutIfNeeded()
    }
}
