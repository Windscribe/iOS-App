//
//  HelpSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol HelpSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var entries: [HelpMenuEntryType] { get set }
    var sendLogStatus: HelpLogStatus { get }

    func entrySelected(_ entry: HelpMenuEntryType)
    func submitDebugLog()
}

class HelpSettingsViewModelImpl: HelpSettingsViewModel {

    @Published var isDarkMode: Bool = false
    @Published var entries: [HelpMenuEntryType] = []
    @Published private(set) var sendLogStatus: HelpLogStatus = .idle
    @Published var alert: HelpAlert?
    @Published var safariURL: URL?
    @Published var selectedRoute: HelpRoute?

    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let sessionManager: SessionManaging
    private let apiManager: APIManager
    private let connectivity: Connectivity
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    private var networkStatus: NetworkStatus = .disconnected

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         sessionManager: SessionManaging,
         apiManager: APIManager,
         connectivity: Connectivity,
         logger: FileLogger) {

        self.lookAndFeelRepository = lookAndFeelRepository
        self.sessionManager = sessionManager
        self.apiManager = apiManager
        self.connectivity = connectivity
        self.logger = logger

        bindSubjects()
        reloadEntries()
    }

    private func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)

        connectivity.network
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] network in
                self?.networkStatus = network.status
            })
            .store(in: &cancellables)
    }

    private func reloadEntries() {
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

        logger.getLogData()
            .asPublisher()
            .flatMap { [weak self] logData -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "VMDisposed", code: -1))
                        .eraseToAnyPublisher()
                }

                var username = self.sessionManager.session?.username ?? ""

                if let session = self.sessionManager.session, session.isUserGhost {
                    username = "ghost_\(session.userId)"
                }

                return self.apiManager.sendDebugLog(username: username, log: logData)
                    .map { _ in true } // map APIMessage → Bool
                    .asPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                if case let .failure(error) = completion {
                    self.sendLogStatus = .failure(error.localizedDescription)
                    self.alert = HelpAlert(
                        title: TextsAsset.appLogSubmitFailAlert,
                        message: "",
                        buttonText: TextsAsset.okay)
                }
            }, receiveValue: { [weak self] _ in
                self?.sendLogStatus = .success
            })
            .store(in: &cancellables)
    }
}
