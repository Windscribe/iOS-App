//
//  AuthTestStubs.swift
//  WindscribeTests
//
//  Minimal stub mocks for auth ViewModel test dependencies.
//  These satisfy the compiler but are not exercised in tests.
//

import Foundation
import Combine
@testable import Windscribe

// MARK: - UserDataRepository

class MockUserDataRepository: UserDataRepository {
    func prepareUserData() async throws {}
}

// MARK: - LookAndFeelRepositoryType

class MockLookAndFeelRepository: LookAndFeelRepositoryType {
    var backgroundChangedTrigger = PassthroughSubject<Void, Never>()
    var isDarkModeSubject = CurrentValueSubject<Bool, Never>(true)
    var backgroundEffectConnect: BackgroundEffectType = .none
    var backgroundEffectDisconnect: BackgroundEffectType = .none
    var backgroundCustomConnectPath: String?
    var backgroundCustomDisconnectPath: String?
    var backgroundCustomAspectRatio: BackgroundAspectRatioType = .fill
    var isDarkMode: Bool = true

    func updateBackgroundEffectConnect(effect: BackgroundEffectType) {}
    func updateBackgroundEffectDisconnect(effect: BackgroundEffectType) {}
    func updateBackgroundCustomConnectPath(path: String) {}
    func updateBackgroundCustomDisconnectPath(path: String) {}
    func updateBackgroundCustomAspectRatio(aspectRatio: BackgroundAspectRatioType) {}
}
