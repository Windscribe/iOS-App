//
//  HelpMeScreenViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class HelpMeScreenViewModel {
    // MARK: - Dependencies
    private let sessionProviding: any SessionProviding
    private let debugLogManaging: any DebugLogManaging
    private let connectivityObserving: any ConnectivityObserving
    private let logger: any LogStoring

    // MARK: - State
    private var hasStarted = false
    private var networkStatus: NetworkStatus = .disconnected

    var sendLogStatus: HelpLogStatus = .idle
    var alert: HelpAlert?
    var safariURL: URL?
    var showingSafari: Bool = false
    var navigationRoute: HelpRoute? {
        didSet {
            isNavigating = navigationRoute != nil
        }
    }
    var isNavigating: Bool = false

    init(
        sessionProviding: any SessionProviding,
        debugLogManaging: any DebugLogManaging,
        connectivityObserving: any ConnectivityObserving,
        logger: any LogStoring
    ) {
        self.sessionProviding = sessionProviding
        self.debugLogManaging = debugLogManaging
        self.connectivityObserving = connectivityObserving
        self.logger = logger

        // Initialize current state
        self.networkStatus = connectivityObserving.currentNetwork.status
    }

    // MARK: - Computed Properties
    var entries: [HelpMenuEntryType] {
        let isUserPro = sessionProviding.session?.isUserPro ?? false

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

        return baseEntries
    }

    // MARK: - Observers
    func startObservers() async {
        guard !hasStarted else { return }
        hasStarted = true

        async let connectivity: () = observeConnectivity()

        _ = await connectivity
    }

    private func observeConnectivity() async {
        for await network in connectivityObserving.networkUpdates {
            networkStatus = network.status
        }
    }

    // MARK: - Actions
    func entrySelected(_ entry: HelpMenuEntryType) {
        switch entry {
        case let .link(_, _, _, urlString):
            if let url = URL(string: urlString) {
                safariURL = url
                showingSafari = true
            }
        case let .navigation(_, _, _, route):
            navigationRoute = route
        case .sendDebugLog:
            submitDebugLog()
        default:
            break
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

                var username = sessionProviding.session?.username ?? ""
                if let session = sessionProviding.session, session.isUserGhost {
                    username = "ghost_\(session.userId)"
                }

                _ = try await debugLogManaging.sendDebugLog(username: username, log: logData)

                self.sendLogStatus = .success
            } catch {
                self.sendLogStatus = .failure(error.localizedDescription)
                self.alert = HelpAlert(
                    title: TextsAsset.appLogSubmitFailAlert,
                    message: "",
                    buttonText: TextsAsset.okay)
            }
        }
    }
}
