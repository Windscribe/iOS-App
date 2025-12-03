//
//  SessionRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 21/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine

protocol SessionRepository {
    var isPremium: Bool { get }
    var isUserPro: Bool { get }
    var session: Session? { get }
    var sessionStatus: Int? { get }
    var email: String? { get }
    var userId: String { get }
    var keepSessionUpdatedTrigger: PassthroughSubject<Void, Never> { get }
    var sessionModelSubject: CurrentValueSubject<Session?, Never> { get }

    func updateSession(_ value: Session?)
    func canAccesstoProLocation() -> Bool
    func keepSessionUpdated()
}

class SessionRepositoryImpl: SessionRepository {

    var keepSessionUpdatedTrigger = PassthroughSubject<Void, Never>()
    var sessionModelSubject = CurrentValueSubject<Session?, Never>(nil)

    var isPremium: Bool {
        return session?.isPremium ?? false
    }

    var isUserPro: Bool {
        return session?.isUserPro ?? false
    }

    var email: String? {
        return session?.email
    }

    var userId: String {
        return session?.userId ?? ""
    }

    var sessionStatus: Int? {
        session?.status
    }

    var session: Session?

    func updateSession(_ value: Session?) {
        session = value
    }

    func canAccesstoProLocation() -> Bool {
        isPremium
    }

    func keepSessionUpdated() {
        keepSessionUpdatedTrigger.send()
    }
}
