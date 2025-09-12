//
//  HelpSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol HelpSettingsViewModel: PreferencesBaseViewModel {
    var entries: [HelpMenuEntryType] { get set }
    var sendLogStatus: HelpLogStatus { get }

    func entrySelected(_ entry: HelpMenuEntryType)
    func submitDebugLog()
}

class HelpSettingsViewModelImpl: PreferencesBaseViewModelImpl, HelpSettingsViewModel {

    @Published var entries: [HelpMenuEntryType] = []
    @Published private(set) var sendLogStatus: HelpLogStatus = .idle
    @Published var alert: HelpAlert?
    @Published var safariURL: URL?
    @Published var selectedRoute: HelpRoute?

    private let sessionManager: SessionManager
    private let apiManager: APIManager
    private let connectivity: ConnectivityManager

    private var networkStatus: NetworkStatus = .disconnected

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         sessionManager: SessionManager,
         apiManager: APIManager,
         connectivity: ConnectivityManager) {

        self.sessionManager = sessionManager
        self.apiManager = apiManager
        self.connectivity = connectivity

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        connectivity.network
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] network in
                self?.networkStatus = network.status
            })
            .store(in: &cancellables)
    }

    override func reloadItems() {
        let isUserPro = sessionManager.session?.isUserPro ?? false

        var baseEntries: [HelpMenuEntryType] = [
            .link(icon: ImagesAsset.Help.apple,
                  title: TextsAsset.Help.knowledgeBase,
                  subtitle: TextsAsset.Help.allYouNeedToknowIsHere,
                  urlString: LinkProvider.getWindscribeLink(path: Links.knowledge)),

                .link(icon: ImagesAsset.Help.garry,
                      title: TextsAsset.Help.talkToGarry,
                      subtitle: TextsAsset.Help.notAsSmartAsSiri,
                      urlString: LinkProvider.getWindscribeLink(path: Links.garry)),

                .communitySupport(
                    redditURLString: Links.reddit,
                    discordURLString: Links.discord
                ),

                .navigation(icon: ImagesAsset.Preferences.advanceParams,
                            title: TextsAsset.Preferences.advanceParameters,
                            subtitle: TextsAsset.Help.advanceParamDescription,
                            route: .advancedParams),

                .navigation(icon: ImagesAsset.Help.debugView,
                            title: TextsAsset.Debug.viewLog,
                            subtitle: nil,
                            route: .viewLog),

                .sendDebugLog(icon: ImagesAsset.Help.debugSend,
                              title: TextsAsset.Debug.sendLog)
        ]

        if isUserPro {
            baseEntries.insert(.navigation(icon: ImagesAsset.Help.ticket,
                                           title: TextsAsset.Help.sendTicket,
                                           subtitle: TextsAsset.Help.sendUsATicket,
                                           route: .sendTicket), at: 2)
        }

        entries = baseEntries
    }

    func entrySelected(_ entry: HelpMenuEntryType) {
        switch entry {
        case let .link(_, _, _, urlString):
            if let url = URL(string: urlString) {
                safariURL = url
            }
        case let .navigation(_, _, _, route):
            selectedRoute = route
        case .sendDebugLog:
            submitDebugLog()
        default: break
        }
    }

    func submitDebugLog() {
        guard networkStatus == .connected else {
            alert = HelpAlert(
                title: TextsAsset.appLogSubmitFailAlert,
                message: "",
                buttonText: TextsAsset.okay)
            return
        }

        sendLogStatus = .sending

        Task {
            do {
                let logData = try await logger.getLogData()

                let username = await MainActor.run {
                    var username = sessionManager.session?.username ?? ""
                    if let session = sessionManager.session, session.isUserGhost {
                        username = "ghost_\(session.userId)"
                    }
                    return username
                }

                _ = try await apiManager.sendDebugLog(username: username, log: logData)

                await MainActor.run {
                    self.sendLogStatus = .success
                }
            } catch {
                await MainActor.run {
                    self.sendLogStatus = .failure(error.localizedDescription)
                    self.alert = HelpAlert(
                        title: TextsAsset.appLogSubmitFailAlert,
                        message: "",
                        buttonText: TextsAsset.okay)
                }
            }
        }
    }
}
