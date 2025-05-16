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

struct CustomRulesEntry: MenuEntryItemType {
    let id: Int = 0
    let mainAction: MenuEntryActionType? = .link(title: nil)
    let message: String? = nil
    let secondaryAction: [MenuEntryActionType] = []
    let title: String = TextsAsset.Robert.manageCustomRules
    let icon: String = ""
}

protocol RobertSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var description: String { get set }
    var errorMessage: String? { get set }
    var safariURL: URL? { get }
    var entries: [RobertFilter] { get set }
    var customRulesEntry: CustomRulesEntry { get }

    func filterSelected(_ filter: RobertFilter)
    func infoSelected()
    func customRulesSelected()
}

final class RobertSettingsViewModelImpl: RobertSettingsViewModel {
    @Published var isDarkMode: Bool = false
    @Published var description: String = TextsAsset.Robert.description
    @Published var errorMessage: String?
    @Published var safariURL: URL?
    @Published var entries: [RobertFilter] = []
    @Published var customRulesEntry = CustomRulesEntry()

    private let logger: FileLogger
    private let apiManager: APIManager
    private let localDB: LocalDatabase
    private let lookAndFeelRepo: LookAndFeelRepositoryType

    private let disposeBag = DisposeBag()

    private var cancellables = Set<AnyCancellable>()

    init(logger: FileLogger,
         apiManager: APIManager,
         localDB: LocalDatabase,
         lookAndFeelRepo: LookAndFeelRepositoryType) {
        self.logger = logger
        self.apiManager = apiManager
        self.localDB = localDB
        self.lookAndFeelRepo = lookAndFeelRepo

        entries = localDB.getRobertFilters()?.getRules() ?? []
        bindSubjects()
    }

    func bindSubjects() {
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
                self.entries = robertFilters.getRules()
            })
            .store(in: &cancellables)
    }

    func filterSelected(_ filter: RobertFilter) {
        let status: Int32 = filter.enabled ? 0 : 1
        apiManager.updateRobertSettings(id: filter.id, status: status)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
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
