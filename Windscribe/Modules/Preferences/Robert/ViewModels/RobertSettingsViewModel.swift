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

protocol RobertSettingsViewModel: PreferencesBaseViewModel {
    var description: AttributedString { get set }
    var errorMessage: String? { get set }
    var safariURL: URL? { get }
    var entries: [RobertFilter] { get set }
    var customRulesEntry: RobertEntryType { get }

    func filterSelected(_ filter: RobertFilter)
    func infoSelected()
    func customRulesSelected()
}

final class RobertSettingsViewModelImpl: PreferencesBaseViewModelImpl, RobertSettingsViewModel {
    @Published var description: AttributedString = AttributedString("")
    @Published var errorMessage: String?
    @Published var safariURL: URL?
    @Published var entries: [RobertFilter] = []
    @Published var customRulesEntry: RobertEntryType = .customRules
    @Published var isLoading: Bool = false

    private let apiManager: APIManager
    private let localDB: LocalDatabase

    private let disposeBag = DisposeBag()

    private var robertFilters: RobertFilters?

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         apiManager: APIManager,
         localDB: LocalDatabase) {
        self.apiManager = apiManager
        self.localDB = localDB

        entries = localDB.getRobertFilters()?.getRules() ?? []

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)

        description = AttributedString(TextsAsset.Robert.description
                                       + " "
                                       + TextsAsset.learnMore)

        if let range = description.range(of: TextsAsset.learnMore) {
            description[range].foregroundColor = .learnBlue
        }
    }

    override func bindSubjects() {
        super.bindSubjects()

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let robertFilters = try await apiManager.getRobertFilters()
                self.localDB.saveRobertFilters(filters: robertFilters).disposed(by: self.disposeBag)
                self.robertFilters = robertFilters
                self.reloadItems()
            } catch {
                if let error = error as? Errors {
                    var newError = ""
                    switch error {
                    case let .apiError(e):
                        newError = e.errorMessage ?? TextsAsset.Robert.failedToGetFilters
                    default:
                        newError = "\(TextsAsset.Robert.failedToGetFilters) \(error.description)"
                    }
                    self.logger.logE("GeneralSettingsViewModel", newError)
                    self.errorMessage = newError
                    if self.entries.isEmpty {
                        self.entries = self.localDB.getRobertFilters()?.getRules() ?? []
                    }
                }
            }
        }
    }

    override func reloadItems() {
        guard let robertFilters = robertFilters else { return }
        entries = robertFilters.getRules()
    }

    func filterSelected(_ filter: RobertFilter) {
        actionSelected()

        // Extract Realm object properties on main thread before entering Task
        let filterId = filter.id
        let status: Int32 = filter.enabled ? 0 : 1
        isLoading = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await apiManager.updateRobertSettings(id: filterId, status: status)

                // Sync Robert filters after successful update
                do {
                    _ = try await apiManager.syncRobertFilters()

                    // Only update toggle state after both API calls succeed
                    await MainActor.run {
                        self.localDB.toggleRobertRule(id: filterId)
                        guard let robertFilters = self.localDB.getRobertFilters() else {
                            let newError = "Unable to load robert rules. Check your network connection."
                            self.logger.logE("GeneralSettingsViewModel", self.errorMessage ?? "")
                            self.errorMessage = newError
                            self.isLoading = false
                            return
                        }
                        self.entries = robertFilters.getRules()
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        if let error = error as? Errors {
                            var newError = ""
                            switch error {
                            case let .apiError(e):
                                newError = e.errorMessage ?? "Failed to sync Robert Settings."
                            default:
                                newError = "Failed to sync Robert Settings. \(error.description)"
                            }
                            self.logger.logE("GeneralSettingsViewModel", newError)
                            self.errorMessage = newError
                        }
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    if let error = error as? Errors {
                        var newError = ""
                        switch error {
                        case let .apiError(e):
                            newError = e.errorMessage ?? TextsAsset.Robert.failedToGetFilters
                        default:
                            newError = "\(TextsAsset.Robert.failedToGetFilters) \(error.description)"
                        }
                        self.logger.logE("GeneralSettingsViewModel", newError)
                        self.errorMessage = newError
                    }
                }
            }
        }
    }

    func infoSelected() {
        safariURL =  URL(string: LinkProvider.getWindscribeLink(path: Links.learMoreAboutRobert))
    }

    func customRulesSelected() {
        actionSelected()

        logger.logI("RobertSettingsViewModelImpl", "User tapped custom rules button.")

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let webSession = try await apiManager.getWebSession()
                await MainActor.run {
                    self.safariURL = LinkProvider.getRobertRulesUrl(session: webSession.tempSession)
                }
            } catch {
                await MainActor.run {
                    if let error = error as? Errors {
                        var newError = ""
                        switch error {
                        case let .apiError(e):
                            newError = e.errorMessage ?? "Failed to update Robert Session for custom rules."
                        default:
                            newError = "Failed to update Robert Session for custom rules. \(error.description)"
                        }
                        self.logger.logE("GeneralSettingsViewModel", newError)
                        self.errorMessage = newError
                    }
                }
            }
        }
    }
}
