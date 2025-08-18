//
//  ProtocolConnectionDebugViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

// MARK: - Protocol Connection Debug ViewModel

/// ViewModel for debug log completion screen
/// Shows success message after debug log has been submitted
protocol ProtocolConnectionDebugViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var shouldDismissCurrentView: Bool { get }
    var shouldDismissAllViews: Bool { get }
    var completionMessage: String { get }
    var safariURL: URL? { get }

    func contactSupport()
    func cancel()
}

final class ProtocolConnectionDebugViewModelImpl: ProtocolConnectionDebugViewModel, ObservableObject {

    @Published var isDarkMode: Bool = false
    @Published var shouldDismissCurrentView: Bool = false
    @Published var shouldDismissAllViews: Bool = false
    @Published var safariURL: URL?

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    /// Completion message shown after debug log is successfully submitted
    var completionMessage: String {
        return TextsAsset.ProtocolVariation.debugLogCompletionDescription
    }

    init(
        lookAndFeelRepository: LookAndFeelRepositoryType,
        logger: FileLogger
    ) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger

        setupBindings()
    }

    private func setupBindings() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ProtocolConnectionDebugViewModel", "Theme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)
    }

    /// Opens support link in SafariView within the app
    func contactSupport() {
        logger.logI("ProtocolConnectionDebugViewModel", "User tapped contact support")
        safariURL = URL(string: LinkProvider.getWindscribeLink(path: Links.helpMe))
    }

    /// Dismisses the entire debug log flow
    func cancel() {
        logger.logI("ProtocolConnectionDebugViewModel", "User dismissed debug log completion screen - closing entire flow")
        shouldDismissAllViews = true
    }
}
