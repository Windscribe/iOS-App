//
//  ConfirmEmailViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-28.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

protocol ConfirmEmailViewModel {
    var sessionManager: SessionManaging { get }
    var localDatabase: LocalDatabase { get }
    var apiManager: APIManager { get }

    func getSession()
    func updateSession()
}

final class ConfirmEmailViewModelImpl: ObservableObject, ConfirmEmailViewModel {

    // MARK: Dependencies
    let sessionManager: SessionManaging
    let localDatabase: LocalDatabase
    let apiManager: APIManager

    // MARK: Published Properties
    @Published var session: Session?
    @Published var resendButtonDisabled: Bool = false
    @Published var resendEmailSuccess: Bool = false
    @Published var shouldDismiss: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init(sessionManager: SessionManaging, localDatabase: LocalDatabase, apiManager: APIManager) {
        self.sessionManager = sessionManager
        self.localDatabase = localDatabase
        self.apiManager = apiManager

        observeSession()
    }

    func getSession() {
        localDatabase.getSession()
            .toPublisher()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] session in
                self?.session = session
                if session?.emailStatus == true {
                    self?.shouldDismiss = true
                }
            })
            .store(in: &cancellables)
    }

    func updateSession() {
        sessionManager.keepSessionUpdated()
    }

    func resendEmail() {
        resendButtonDisabled = true

        apiManager.confirmEmail()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure = completion {
                    self?.resendButtonDisabled = false
                }
            }, receiveValue: { [weak self] _ in
                self?.resendEmailSuccess = true
            })
            .store(in: &cancellables)
    }

    private func observeSession() {
        getSession()

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateSession()
            }
            .store(in: &cancellables)
    }
}
