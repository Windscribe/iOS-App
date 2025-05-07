//
//  LookAndFeelRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol LookAndFeelRepositoryType {
    // Subjects
    var backgroundChangedTrigger: PublishSubject<Void> { get }
    var isDarkModeSubject: BehaviorSubject<Bool> { get }

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
    var backgroundChangedTrigger = PublishSubject<Void>()
    var isDarkModeSubject = BehaviorSubject<Bool>(value: true)

    var backgroundEffectConnect: BackgroundEffectType
    var backgroundEffectDisconnect: BackgroundEffectType
    var backgroundCustomConnectPath: String?
    var backgroundCustomDisconnectPath: String?
    var backgroundCustomAspectRatio: BackgroundAspectRatioType
    var isDarkMode: Bool

    let preferences: Preferences

    private let disposeBag = DisposeBag()

    init(preferences: Preferences) {
        self.preferences = preferences
        backgroundEffectConnect = BackgroundEffectType.fromRaw(value: preferences.getBackgroundEffectConnect() ?? "")
        backgroundEffectDisconnect = BackgroundEffectType.fromRaw(value: preferences.getBackgroundEffectDisconnect() ?? "")
        backgroundCustomConnectPath = preferences.getBackgroundCustomConnectPath()
        backgroundCustomDisconnectPath = preferences.getBackgroundCustomDisconnectPath()
        backgroundCustomAspectRatio = BackgroundAspectRatioType(aspectRatioType: preferences.getAspectRatio() ?? "")

        isDarkMode = true

        preferences.getDarkMode()
            .subscribe(onNext: { theme in
                self.isDarkMode = theme ?? DefaultValues.darkMode
                self.isDarkModeSubject.onNext(self.isDarkMode)
            }, onError: { _ in
                self.isDarkMode = true
                self.isDarkModeSubject.onNext(self.isDarkMode)
            }).disposed(by: disposeBag)
    }

    func updateBackgroundEffectConnect(effect: BackgroundEffectType) {
        backgroundEffectConnect = effect
        preferences.saveBackgroundEffectConnect(value: effect.preferenceValue)
        backgroundChangedTrigger.onNext(())
    }

    func updateBackgroundEffectDisconnect(effect: BackgroundEffectType) {
        backgroundEffectDisconnect = effect
        preferences.saveBackgroundEffectDisconnect(value: effect.preferenceValue)
        backgroundChangedTrigger.onNext(())
    }

    func updateBackgroundCustomConnectPath(path: String) {
        backgroundCustomConnectPath = path
        preferences.saveBackgroundCustomConnectPath(value: path)
        backgroundChangedTrigger.onNext(())
    }

    func updateBackgroundCustomDisconnectPath(path: String) {
        backgroundCustomDisconnectPath = path
        preferences.saveBackgroundCustomDisconnectPath(value: path)
        backgroundChangedTrigger.onNext(())
    }

    func updateBackgroundCustomAspectRatio(aspectRatio: BackgroundAspectRatioType) {
        backgroundCustomAspectRatio = aspectRatio
        preferences.saveAspectRatio(value: aspectRatio.preferenceValue)
        backgroundChangedTrigger.onNext(())
    }
}
