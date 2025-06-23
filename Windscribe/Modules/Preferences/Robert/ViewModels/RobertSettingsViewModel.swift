//
//  RobertSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import RxSwift

enum RobertEntryType: MenuEntryHeaderType, Hashable, Equatable {
    case customRules

    var id: Int { 1 }
    var action: MenuEntryActionType? { .none(title: TextsAsset.Robert.manageCustomRules, parentId: id) }
    var message: String? { nil }
    var secondaryEntries: [MenuSecondaryEntryItem] { [] }
    var title: String { TextsAsset.Robert.manageCustomRules }
    var icon: String { "" }
}

protocol RobertSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var description: AttributedString { get set }
    var errorMessage: String? { get set }
    var safariURL: URL? { get }
    var entries: [RobertFilter] { get set }
    var customRulesEntry: RobertEntryType { get }

    func filterSelected(_ filter: RobertFilter)
    func infoSelected()
    func customRulesSelected()
}

final class RobertSettingsViewModelImpl: RobertSettingsViewModel {
    @Published var isDarkMode: Bool = false
    @Published var description: AttributedString = AttributedString("")
    @Published var errorMessage: String?
    @Published var safariURL: URL?
    @Published var entries: [RobertFilter] = []
    @Published var customRulesEntry: RobertEntryType = .customRules
    @Published var isLoading: Bool = false

    private let logger: FileLogger
    private let apiManager: APIManager
    private let localDB: LocalDatabase
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    private let disposeBag = DisposeBag()

    private var cancellables = Set<AnyCancellable>()
    private var robertFilters: RobertFilters?

    init(logger: FileLogger,
         apiManager: APIManager,
         localDB: LocalDatabase,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.logger = logger
        self.apiManager = apiManager
        self.localDB = localDB
        self.lookAndFeelRepository = lookAndFeelRepository

        entries = localDB.getRobertFilters()?.getRules() ?? []
        bindSubjects()

        description = AttributedString(TextsAsset.Robert.description
                                       + " "
                                       + TextsAsset.learnMore)

        if let range = description.range(of: TextsAsset.learnMore) {
            description[range].foregroundColor = .learnBlue
        }
    }

    func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("RobertSettingsViewModel", "Theme Adjustment Change error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
                self?.reloadEntries()
            })
            .store(in: &cancellables)

        apiManager.getRobertFilters()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion,
                   let error = error as? Errors {
                    var newError = ""
                    switch error {
                    case let .apiError(e):
                        newError = e.errorMessage ?? "Failed to get Robert Filters."
                    default:
                        newError = "Failed to get Robert Filters. \(error.description)"
                    }
                    self.logger.logE("GeneralSettingsViewModel", newError)
                    errorMessage = newError
                    if self.entries.isEmpty {
                        self.entries = self.localDB.getRobertFilters()?.getRules() ?? []
                    }
                }
            }, receiveValue: { [weak self] robertFilters in
                guard let self = self else { return }
                self.localDB.saveRobertFilters(filters: robertFilters).disposed(by: self.disposeBag)
                self.robertFilters = robertFilters
                self.reloadEntries()
            })
            .store(in: &cancellables)
    }

    private func reloadEntries() {
        guard let robertFilters = robertFilters else { return }
        entries = robertFilters.getRules()
    }

    func filterSelected(_ filter: RobertFilter) {
        let status: Int32 = filter.enabled ? 0 : 1
        isLoading = true

        apiManager.updateRobertSettings(id: filter.id, status: status)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false

                if case let .failure(error) = completion,
                   let error = error as? Errors {
                    var newError = ""
                    switch error {
                    case let .apiError(e):
                        newError = e.errorMessage ?? "Failed to update Robert Setting."
                    default:
                        newError = "Failed to update Robert Setting. \(error.description)"
                    }
                    self.logger.logE("GeneralSettingsViewModel", newError)
                    errorMessage = newError
                }
            }, receiveValue: { [weak self] robertFilters in
                guard let self = self else { return }
                self.localDB.toggleRobertRule(id: filter.id)
                guard let robertFilters = self.localDB.getRobertFilters() else {
                    let newError = "Unable to load robert rules. Check your network connection."
                    self.logger.logE("GeneralSettingsViewModel", errorMessage ?? "")
                    errorMessage = newError
                    return
                }
                self.entries = robertFilters.getRules()
                self.apiManager.syncRobertFilters()
                    .asPublisher()
                    .sink(receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }
                        if case let .failure(error) = completion,
                           let error = error as? Errors {
                            var newError = ""
                            switch error {
                            case let .apiError(e):
                                newError = e.errorMessage ?? "Failed to sync Robert Setting."
                            default:
                                newError = "Failed to sync Robert Setting. \(error.description)"
                            }
                            self.logger.logE("GeneralSettingsViewModel", newError)
                            errorMessage = newError
                        }
                    }, receiveValue: {_ in})
                    .store(in: &cancellables)

                self.isLoading = false
            })
            .store(in: &cancellables)
    }

    func infoSelected() {
        safariURL =  URL(string: LinkProvider.getWindscribeLink(path: Links.learMoreAboutRobert))
    }

    func customRulesSelected() {
        logger.logI(self, "User tapped custom rules button.")
        apiManager.getWebSession()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion,
                   let error = error as? Errors {
                    var newError = ""
                    switch error {
                    case let .apiError(e):
                        newError = e.errorMessage ?? "Failed to update Robert Session for custom rules."
                    default:
                        newError = "Failed to update Robert Session for custom rules. \(error.description)"
                    }
                    self.logger.logE("GeneralSettingsViewModel", newError)
                    errorMessage = newError
                }
            }, receiveValue: { [weak self] webSession in
                self?.safariURL = LinkProvider.getRobertRulesUrl(session: webSession.tempSession)
            })
            .store(in: &cancellables)
    }
}
