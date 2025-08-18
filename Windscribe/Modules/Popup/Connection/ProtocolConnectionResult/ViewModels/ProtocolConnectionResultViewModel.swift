//
//  ProtocolConnectionResultViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ProtocolConnectionResultViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var shouldDismiss: Bool { get }
    var shouldNavigateToLogCompleted: Bool { get }
    var protocolName: String { get }
    var viewType: ProtocolViewType { get }
    var submitLogState: ProtocolConnectionLogState { get }
    var isLoading: Bool { get }

    func setAsPreferred()
    func submitDebugLog()
    func cancel()
}

final class ProtocolConnectionResultViewModelImpl: ProtocolConnectionResultViewModel, ObservableObject {

    @Published var isDarkMode: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var shouldNavigateToLogCompleted: Bool = false
    @Published var protocolName: String = ""
    @Published var viewType: ProtocolViewType = .connected
    @Published var submitLogState: ProtocolConnectionLogState = .initial
    @Published var isLoading: Bool = false

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let securedNetwork: SecuredNetworkRepository
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let sessionManager: SessionManaging
    private let apiManager: APIManager
    private let protocolManager: ProtocolManagerType

    private var cancellables = Set<AnyCancellable>()

    /// Reactive trigger for log submission completion - used for navigation
    private let logSubmittedTrigger = PassthroughSubject<Void, Never>()

    /// Reactive trigger for preferred protocol set - used for dismissal
    private let preferredProtocolSetTrigger = PassthroughSubject<Void, Never>()

    /// Title text based on success/failure scenario
    var titleText: String {
        switch viewType {
        case .connected, .normal:
            return TextsAsset.SetPreferredProtocolPopup.title(protocolType: protocolName.uppercased())
        case .fail:
            return TextsAsset.SetPreferredProtocolPopup.failHeaderString
        case .nextUp:
            return ""
        }
    }

    /// Description text based on success/failure scenario
    var descriptionText: String {
        switch viewType {
        case .connected, .normal:
            return TextsAsset.SetPreferredProtocolPopup.changeMessage
        case .fail:
            return TextsAsset.SetPreferredProtocolPopup.failMessage
        case .nextUp:
            return ""
        }
    }

    /// Whether to show the "Set as Preferred" button
    var showSetPreferredButton: Bool {
        return viewType != .fail
    }

    /// Whether to show the "Send Debug Log" button
    var showSendDebugLogButton: Bool {
        return viewType == .fail
    }

    // MARK: - Initialization

    init(
        lookAndFeelRepository: LookAndFeelRepositoryType,
        securedNetwork: SecuredNetworkRepository,
        localDatabase: LocalDatabase,
        logger: FileLogger,
        sessionManager: SessionManaging,
        apiManager: APIManager,
        protocolManager: ProtocolManagerType
    ) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.securedNetwork = securedNetwork
        self.localDatabase = localDatabase
        self.logger = logger
        self.sessionManager = sessionManager
        self.apiManager = apiManager
        self.protocolManager = protocolManager

        setupBindings()
    }

    private func setupBindings() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ProtocolConnectionResultViewModel", "Theme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)

        logSubmittedTrigger
            .sink { [weak self] in
                self?.handleLogSubmissionCompleted()
            }
            .store(in: &cancellables)

        preferredProtocolSetTrigger
            .sink { [weak self] in
                self?.shouldDismiss = true
                self?.logger.logI("ProtocolConnectionResultViewModel", "Preferred protocol set")
            }
            .store(in: &cancellables)
    }

    /// Sets the current protocol as preferred for the current network
    /// This saves the protocol preference to the local database for WiFi networks
    func setAsPreferred() {
        guard let network = securedNetwork.getCurrentNetwork() else {
            logger.logI("ProtocolConnectionResultViewModel", "No current network found")
            return
        }

        guard let portsArray = localDatabase.getPorts(protocolType: protocolName),
              let defaultPort = portsArray.first else {
            logger.logE("ProtocolConnectionResultViewModel", "No ports found for protocol: \(protocolName)")
            return
        }

        logger.logI("ProtocolConnectionResultViewModel",
                   "Setting preferred protocol: \(protocolName) port: \(defaultPort) for network: \(network.SSID)")

        // Update the WiFi network with preferred protocol settings
        localDatabase.updateWifiNetwork(
            network: network,
            properties: [
                Fields.WifiNetwork.preferredProtocol: protocolName,
                Fields.WifiNetwork.preferredPort: defaultPort,
                Fields.WifiNetwork.preferredProtocolStatus: true
            ]
        )

        // Trigger reactive completion
        preferredProtocolSetTrigger.send()
    }

    /// Submits debug logs to support for troubleshooting failed connections
    /// This handles the complete log collection and submission process
    func submitDebugLog() {
        guard submitLogState != .sending else {
            logger.logI("ProtocolConnectionResultViewModel", "Log submission already in progress")
            return
        }

        submitLogState = .sending
        isLoading = true

        logger.logD("ProtocolConnectionResultViewModel", "Starting debug log submission")

        Task {
            do {
                // Collect log data from logger
                let logData = try await logger.getLogData()

                // Get username, handling ghost accounts
                let username = await MainActor.run {
                    var username = sessionManager.session?.username ?? ""
                    if let session = sessionManager.session, session.isUserGhost {
                        username = "ghost_\(session.userId)"
                    }
                    return username
                }

                logger.logD("ProtocolConnectionResultViewModel", "Collected log data for user: \(username)")

                // Submit logs via API
                let response = try await apiManager.sendDebugLog(
                    username: username,
                    log: logData
                )

                await MainActor.run {
                    if response.success {
                        self.submitLogState = .sent
                        self.logger.logD("ProtocolConnectionResultViewModel", "Debug log submitted successfully")
                        // Navigate to completion screen
                        self.shouldNavigateToLogCompleted = true
                    } else {
                        self.submitLogState = .failed
                        self.logger.logE("ProtocolConnectionResultViewModel", "Debug log submission failed: \(response.message)")
                    }
                    self.isLoading = false
                }

            } catch {
                await MainActor.run {
                    self.submitLogState = .failed
                    self.isLoading = false
                    self.logger.logE("ProtocolConnectionResultViewModel", "Debug log submission error: \(error)")
                }
            }
        }
    }

    /// Handles cancel action - resets failure counts and dismisses
    func cancel() {
        logger.logD("ProtocolConnectionResultViewModel", "User canceled protocol result dialog")

        // Reset automatic mode failure counts when user cancels
        AutomaticMode.shared.resetFailCounts()

        shouldDismiss = true
    }

    /// Loads the current protocol name from ProtocolManager
    /// This is used when protocol name is not provided in context
    private func loadCurrentProtocolName() {
        let currentProtocol = protocolManager.getProtocol()
        if self.protocolName.isEmpty {
            self.protocolName = currentProtocol.protocolName
        }
    }

    /// Handles log submission completion by triggering navigation
    private func handleLogSubmissionCompleted() {
        logger.logI("ProtocolConnectionResultViewModel", "Log submission completed - should navigate to completion screen")
        shouldNavigateToLogCompleted = true
    }

    /// Updates the view model with context data from router
    func updateFromContext(_ context: ProtocolConnectionResultContext) {
        self.protocolName = context.protocolName
        self.viewType = context.viewType

        logger.logI("ProtocolConnectionResultViewModel",
                   "Updated from context - protocol: \(protocolName), type: \(viewType)")

        // Load protocol name if not provided
        if protocolName.isEmpty {
            loadCurrentProtocolName()
        }
    }

    deinit {
        logger.logD("ProtocolConnectionResultViewModel", "ViewModel deallocated")
    }
}

/// Context object for passing data between router and view
final class ProtocolConnectionResultContext: ObservableObject {
    @Published var protocolName: String = ""
    @Published var viewType: ProtocolViewType = .connected
}
