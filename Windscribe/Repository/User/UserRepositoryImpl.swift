//
//  UserRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxRealm
import RxSwift
import Swinject
class UserRepositoryImpl: UserRepository {
    private let preferences: Preferences
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let vpnmanager: VPNManager
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    let user = BehaviorSubject<User?>(value: nil)
    var sessionAuth: String? {
        return preferences.userSessionAuth()
    }

    init(preferences: Preferences, apiManager: APIManager, localDatabase: LocalDatabase, vpnmanager: VPNManager, logger: FileLogger) {
        self.preferences = preferences
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.vpnmanager = vpnmanager
        self.logger = logger
        localDatabase.getSession().subscribe(onNext: { [self] session in
            self.user.onNext(User(session: session))
        }, onError: { [self] _ in
            self.user.onNext(nil)
        }).disposed(by: disposeBag)

    }

    func getUpdatedUser() -> Single<User> {
        return apiManager.getSession().flatMap { session in
            self.localDatabase.saveOldSession()
            self.localDatabase.saveSession(session: session).disposed(by: self.disposeBag)
            let user = User(session: session)
            self.user.onNext(user)
            return Single.just(user)
        }
    }

    func login(session: Session) {
        preferences.saveUserSessionAuth(sessionAuth: session.sessionAuthHash)
        localDatabase.saveOldSession()
        localDatabase.saveSession(session: session).disposed(by: disposeBag)
        user.onNext(User(session: session))
    }
}
