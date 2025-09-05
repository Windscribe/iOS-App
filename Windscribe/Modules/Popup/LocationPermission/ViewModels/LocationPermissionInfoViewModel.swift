//
//  LocationPermissionModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-07-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol LocationPermissionInfoViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var accessDenied: Bool { get set }

    func handlePrimaryAction()
    func onDisappear()
}

final class LocationPermissionInfoViewModelImpl: LocationPermissionInfoViewModel {

    @Published var isDarkMode: Bool = false
    @Published var accessDenied: Bool = false
    @Published var shouldDismiss: Bool = false

    private let manager: LocationPermissionManaging
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private var cancellables = Set<AnyCancellable>()

    init(manager: LocationPermissionManaging,
         logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.manager = manager
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("LocationPermissionInfoViewModel", "Theme subscription error: \(error)")
                }
            }, receiveValue: { [weak self] in
                self?.isDarkMode = $0
            })
            .store(in: &cancellables)

        manager.locationStatusSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                self.accessDenied = (status == .denied)
                if status == .authorizedWhenInUse {
                    self.shouldDismiss = true
                }
            }.store(in: &cancellables)
    }

    func handlePrimaryAction() {
        if accessDenied {
            manager.openSettings()
        } else {
            manager.grantPermission()
        }
    }

    func onDisappear() {
        manager.permissionPopupClosed()
    }
}
