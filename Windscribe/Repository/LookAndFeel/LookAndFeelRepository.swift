//
//  LookAndFeelRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol LookAndFeelRepositoryType {
    // Subjects
    var backgroundChangedTrigger: PassthroughSubject<Void, Never> { get }
    var isDarkModeSubject: CurrentValueSubject<Bool, Never> { get }

    // Getters
    var backgroundEffectConnect: BackgroundEffectType { get }
    var backgroundEffectDisconnect: BackgroundEffectType { get }

    var backgroundCustomConnectPath: String? { get }
    var backgroundCustomDisconnectPath: String? { get }

    var backgroundCustomAspectRatio: BackgroundAspectRatioType { get }

    var isDarkMode: Bool { get }

    // update funcs
    func updateBackgroundEffectConnect(effect: BackgroundEffectType)
    func updateBackgroundEffectDisconnect(effect: BackgroundEffectType)

    func updateBackgroundCustomConnectPath(path: String)
    func updateBackgroundCustomDisconnectPath(path: String)

    func updateBackgroundCustomAspectRatio(aspectRatio: BackgroundAspectRatioType)
}

class LookAndFeelRepository: LookAndFeelRepositoryType {
    var backgroundChangedTrigger = PassthroughSubject<Void, Never>()
    var isDarkModeSubject = CurrentValueSubject<Bool, Never>(true)

    var backgroundEffectConnect: BackgroundEffectType
    var backgroundEffectDisconnect: BackgroundEffectType
    var backgroundCustomConnectPath: String?
    var backgroundCustomDisconnectPath: String?
    var backgroundCustomAspectRatio: BackgroundAspectRatioType
    var isDarkMode: Bool

    let preferences: Preferences

    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences) {
        self.preferences = preferences
        backgroundEffectConnect = BackgroundEffectType.fromRaw(value: preferences.getBackgroundEffectConnect() ?? "")
        backgroundEffectDisconnect = BackgroundEffectType.fromRaw(value: preferences.getBackgroundEffectDisconnect() ?? "")
        backgroundCustomConnectPath = preferences.getBackgroundCustomConnectPath()
        backgroundCustomDisconnectPath = preferences.getBackgroundCustomDisconnectPath()
        backgroundCustomAspectRatio = BackgroundAspectRatioType(aspectRatioType: preferences.getAspectRatio() ?? "")

        isDarkMode = true

        preferences.getDarkMode()
            .sink { theme in
                self.isDarkMode = theme ?? DefaultValues.darkMode
                self.isDarkModeSubject.send(self.isDarkMode)
            }
            .store(in: &cancellables)
    }

    func updateBackgroundEffectConnect(effect: BackgroundEffectType) {
        backgroundEffectConnect = effect
        preferences.saveBackgroundEffectConnect(value: effect.preferenceValue)
        backgroundChangedTrigger.send(())
    }

    func updateBackgroundEffectDisconnect(effect: BackgroundEffectType) {
        backgroundEffectDisconnect = effect
        preferences.saveBackgroundEffectDisconnect(value: effect.preferenceValue)
        backgroundChangedTrigger.send(())
    }

    func updateBackgroundCustomConnectPath(path: String) {
        backgroundCustomConnectPath = path
        preferences.saveBackgroundCustomConnectPath(value: path)
        backgroundChangedTrigger.send(())
    }

    func updateBackgroundCustomDisconnectPath(path: String) {
        backgroundCustomDisconnectPath = path
        preferences.saveBackgroundCustomDisconnectPath(value: path)
        backgroundChangedTrigger.send(())
    }

    func updateBackgroundCustomAspectRatio(aspectRatio: BackgroundAspectRatioType) {
        backgroundCustomAspectRatio = aspectRatio
        preferences.saveAspectRatio(value: aspectRatio.preferenceValue)
        backgroundChangedTrigger.send(())
    }
}
