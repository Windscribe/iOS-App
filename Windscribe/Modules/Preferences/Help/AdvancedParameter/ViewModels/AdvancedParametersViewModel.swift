//
//  AdvancedParameterViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum AdvanceParamsErrors: Error {
    case invalidKeyValuePair
}

protocol AdvancedParametersViewModel: ObservableObject {
    var titleText: String { get }
    var advanceParams: String { get set }
    var showProgressBar: Bool { get }
    var showError: Bool { get }
    var isDarkMode: Bool { get }

    func saveButtonTap()
    func onAdvanceParamsTextChange(text: String)
    func load()
}

final class AdvancedParametersViewModelImpl: AdvancedParametersViewModel {

    private let preferences: Preferences
    private let apiManager: APIManager
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    @Published var advanceParams: String = ""
    @Published var showProgressBar: Bool = false
    @Published var showError: Bool = false
    @Published var isDarkMode: Bool = false

    var titleText = TextsAsset.Preferences.advanceParameters

    private var cancellables = Set<AnyCancellable>()
    private var hasLoaded = false

    init(preferences: Preferences, apiManager: APIManager, lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.preferences = preferences
        self.apiManager = apiManager
        self.lookAndFeelRepository = lookAndFeelRepository

        bind()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true

        preferences.getAdvanceParams()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] params in
                self?.advanceParams = params ?? ""
            }
            .store(in: &cancellables)
    }

    func onAdvanceParamsTextChange(text: String) {
        showError = false
        advanceParams = text
    }

    func saveButtonTap() {
        showProgressBar = true

        parseAdvanceParams()
            .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .flatMap { [weak self] params -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: AdvanceParamsErrors.invalidKeyValuePair).eraseToAnyPublisher()
                }

                return asVoidPublisher {
                    self.preferences.saveAdvanceParams(params: params)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.showProgressBar = false

                if case let .failure(error) = completion,
                   let error = error as? AdvanceParamsErrors,
                   error == .invalidKeyValuePair {
                    self?.showError = true
                }
            }, receiveValue: { [weak self] _ in
                self?.load()
            })
            .store(in: &cancellables)
    }

    private func parseAdvanceParams() -> AnyPublisher<String, Error> {
        let lines = advanceParams.split(separator: "\n")

        for line in lines {
            let components = line.split(separator: "=")
            if components.count != 2 {
                return Fail(error: AdvanceParamsErrors.invalidKeyValuePair).eraseToAnyPublisher()
            }
        }

        return Just(advanceParams)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
