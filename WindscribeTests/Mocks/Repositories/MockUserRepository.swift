//
//  MockUserRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

@testable import Windscribe

struct MockUserRepository: UserRepository {

    // MARK: - UserRepository Protocol Requirements

    var sessionAuth: String? = "mock-session-auth"

    var user: BehaviorSubject<User?> = BehaviorSubject<User?>(value: nil)

    func getUpdatedUser() -> Single<User> {
        // Return a mock user - adjust the initializer based on your actual User model
        return Single.just(User(session: createMockSession()))
    }

    func login(session: Session) {
        // Mock implementation - create a user from the session
        let mockUser = User(session: session)
        user.onNext(mockUser)
    }

    func update(session: Session) {
        // Mock implementation - update the user with session data
        let mockUser = User(session: session)
        user.onNext(mockUser)
    }

    // MARK: - Helper Methods

    private func createMockSession() -> Session {
        let mockSession = Session()
        mockSession.userId = "123"
        mockSession.username = "Andre"
        mockSession.sessionAuthHash = sessionAuth ?? "mock-auth-hash"
        return mockSession
    }
}
