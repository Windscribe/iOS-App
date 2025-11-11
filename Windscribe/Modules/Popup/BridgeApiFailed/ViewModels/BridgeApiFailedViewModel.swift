//
//  BridgeApiFailedViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 04/11/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum BridgeApiPopupType {
    case rotateIp
    case pinIp

    var title: String {
        switch self {
        case .pinIp:
            return TextsAsset.BridgeAPIIpPinning.title
        case .rotateIp:
            return TextsAsset.BridgeAPIIpRotation.title
        }
    }

    var body: String {
        switch self {
        case .pinIp:
            return TextsAsset.BridgeAPIIpPinning.body
        case .rotateIp:
            return TextsAsset.BridgeAPIIpRotation.body
        }
    }

    var actionButtonText: String {
        switch self {
        case .pinIp:
            return TextsAsset.BridgeAPIIpPinning.actionTitle
        case .rotateIp:
            return TextsAsset.BridgeAPIIpRotation.actionTitle
        }
    }

    var imageName: String {
        return ImagesAsset.Garry.con
    }
}

protocol BridgeApiFailedViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var shouldDismiss: Bool { get set }
    var safariURL: URL? { get }
    var popupType: BridgeApiPopupType { get }

    func updatePopupType(_ type: BridgeApiPopupType)
    func handlePrimaryAction()
    func handleDismissAction()
}

final class BridgeApiFailedViewModelImpl: BridgeApiFailedViewModel {
    @Published var isDarkMode = false
    @Published var shouldDismiss: Bool = false
    @Published var safariURL: URL?
    @Published var popupType: BridgeApiPopupType = .pinIp

    private var cancellables = Set<AnyCancellable>()

    private let lookAndFeelRepository: LookAndFeelRepositoryType

    init(lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.lookAndFeelRepository = lookAndFeelRepository
        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.isDarkMode = $0
            }
            .store(in: &cancellables)
    }

    func updatePopupType(_ type: BridgeApiPopupType) {
        popupType = type
    }

    func handlePrimaryAction() {
        safariURL = URL(string: Links.status)
    }

    func handleDismissAction() {
        shouldDismiss = true
    }
}
