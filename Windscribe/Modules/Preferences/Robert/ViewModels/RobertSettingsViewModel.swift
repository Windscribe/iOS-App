//
//  RobertSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

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
    var entries: [RobertFilterModel] { get set }
    var customRulesEntry: RobertEntryType { get }

    func filterSelected(_ filter: RobertFilterModel)
    func infoSelected()
    func customRulesSelected()
}

final class RobertSettingsViewModelImpl: PreferencesBaseViewModelImpl, RobertSettingsViewModel {
    @Published var description: AttributedString = AttributedString("")
    @Published var errorMessage: String?
    @Published var safariURL: URL?
    @Published var entries: [RobertFilterModel] = []
    @Published var customRulesEntry: RobertEntryType = .customRules
    @Published var isLoading: Bool = false

    private let robertyFiltersRepository: RobertyFiltersRepository

    private let apiManager: APIManager

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         apiManager: APIManager,
         robertyFiltersRepository: RobertyFiltersRepository) {
        self.apiManager = apiManager
        self.robertyFiltersRepository = robertyFiltersRepository

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
                try await robertyFiltersRepository.refreshFilters()
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
                }
            }

            robertyFiltersRepository.robertFilters
                .receive(on: DispatchQueue.main)
                .sink { [weak self] robertFilters in
                    self?.entries = robertFilters
                }
                .store(in: &cancellables)
        }
    }

    override func reloadItems() {
        entries = robertyFiltersRepository.robertFilters.value
    }

    func filterSelected(_ filter: RobertFilterModel) {
        actionSelected()

        isLoading = true

        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await robertyFiltersRepository.updateFilter(filter)
            } catch {
                if let error = error as? RobertFilterErrors {
                    await MainActor.run {
                        switch error {
                        case .failedSync(let message), .failedUpdate(let message):
                            self.errorMessage = message
                        }
                    }
                }
            }
            await MainActor.run {
                self.isLoading = false
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
