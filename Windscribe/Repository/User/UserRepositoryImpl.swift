//
//  UserRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject

class UserRepositoryImpl: UserRepository {
    private let preferences: Preferences
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let wgCredentials: WgCredentials
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    let user = BehaviorSubject<User?>(value: nil)
    var sessionAuth: String? {
        return preferences.userSessionAuth()
    }

    init(preferences: Preferences, apiManager: APIManager, localDatabase: LocalDatabase,  wgCredentials: WgCredentials, logger: FileLogger) {
        self.preferences = preferences
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.wgCredentials = wgCredentials
        self.logger = logger
        localDatabase.getSession().subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { [self] session in
            if let session = session {
                self.user.onNext(User(session: session))
            } else {
                self.user.onNext(nil)
            }
        }, onError: { [self] _ in
            self.user.onNext(nil)
        }).disposed(by: disposeBag)
    }

    func getUpdatedUser() -> Single<User> {
        return apiManager.getSession(nil).flatMap { session in
            self.localDatabase.saveOldSession()
            self.localDatabase.saveSession(session: session).disposed(by: self.disposeBag)
            let user = User(session: session)
            self.user.onNext(user)
            return Single.just(user)
        }
    }

    func login(session: Session) {
        wgCredentials.delete()
        preferences.saveUserSessionAuth(sessionAuth: session.sessionAuthHash)
        localDatabase.saveOldSession()
        localDatabase.saveSession(session: session).disposed(by: disposeBag)
        user.onNext(User(session: session))
    }

    func update(session: Session) {
        localDatabase.saveSession(session: session).disposed(by: disposeBag)
        user.onNext(User(session: session))
    }
}
