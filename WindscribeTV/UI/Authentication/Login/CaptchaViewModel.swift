//
//  CaptchaViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-06-27.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CaptchaViewModel {
    let submitCaptcha = PublishSubject<String>()
    let cancel = PublishSubject<Void>()

    let captchaImage = BehaviorSubject<UIImage?>(value: nil)
    let isLoading = BehaviorSubject<Bool>(value: false)
    let errorMessage = BehaviorSubject<String?>(value: nil)

    let loginSuccess = PublishSubject<Session>()
    let loginError = PublishSubject<Error>()
    let captchaDismiss = PublishSubject<Void>()

    private let disposeBag = DisposeBag()

    private let asciiArtBase64: String
    private let username: String
    private let password: String
    private let twoFactorCode: String?
    private let secureToken: String

    private let apiCallManager: APIManager
    private let logger: FileLogger

    init(
        asciiArtBase64: String,
        username: String,
        password: String,
        twoFactorCode: String?,
        secureToken: String,
        apiCallManager: APIManager,
        logger: FileLogger
    ) {
        self.asciiArtBase64 = asciiArtBase64
        self.username = username
        self.password = password
        self.twoFactorCode = twoFactorCode
        self.secureToken = secureToken
        self.apiCallManager = apiCallManager
        self.logger = logger
        setupBindings()
    }

    private func setupBindings() {
        if let image = UIImage.fromAsciiBase64(asciiArtBase64) {
            captchaImage.onNext(image)
        } else {
            errorMessage.onNext("Unable to render captcha image.")
        }

        // Submit
        submitCaptcha
          .do(onNext: { _ in })
          .subscribe(onNext: { [weak self] code in
            self?.verifyCaptchaAndLogin(with: code)
          })
          .disposed(by: disposeBag)

        // Cancel
        cancel
            .subscribe(onNext: { [weak self] in
                self?.logger.logD("CaptchaViewModel", "Captcha cancelled by user")
            })
            .disposed(by: disposeBag)

    }

    private func verifyCaptchaAndLogin(with solution: String) {
        isLoading.onNext(true)
        logger.logD("CaptchaViewModel", "Verifying captcha with solution: \(solution)")

        apiCallManager.login(
            username: username,
            password: password,
            code2fa: twoFactorCode ?? "",
            secureToken: secureToken,
            captchaSolution: solution,
            captchaTrailX: [],
            captchaTrailY: []
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] session in
            guard let self = self else { return }
            self.logger.logI("CaptchaViewModel", "Login successful after captcha.")
            self.captchaDismiss.onNext(())

            self.loginSuccess.onNext(session)
        }, onFailure: { [weak self] error in
            guard let self else { return }
            self.logger.logE("CaptchaViewModel", "Captcha login failed: \(error)")
            self.isLoading.onNext(false)
            self.captchaDismiss.onNext(())

            self.loginError.onNext(error)
        })
        .disposed(by: disposeBag)
    }
}
