//
//  IPInfoViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 25/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import RxSwift

protocol IPInfoViewModelType {
    var isBlurStaticIpAddress: Bool { get }
    var statusSubject: BehaviorSubject<ConnectionState?> { get }
    var ipAddressSubject: PublishSubject<String> { get }
    var cardHeaderTypeSubject: BehaviorSubject<CardHeaderButtonType?> { get }

    func markBlurStaticIpAddress(isBlured: Bool)
    func updateCardHeaderType(with headerType: CardHeaderButtonType)
}

class IPInfoViewModel: IPInfoViewModelType {
    let preferences: Preferences
    let ipRepository: IPRepository
    let statusSubject = BehaviorSubject<ConnectionState?>(value: nil)
    let cardHeaderTypeSubject = BehaviorSubject<CardHeaderButtonType?>(value: nil)
    let ipAddressSubject = PublishSubject<String>()
    let disposeBag = DisposeBag()

    init(ipRepository: IPRepository, preferences: Preferences) {
        self.preferences = preferences
        self.ipRepository = ipRepository

        ipRepository.ipState
            .compactMap { state -> MyIP? in
                guard case .available(let ip) = state, !ip.isInvalidated else {
                    return nil
                }
                return ip
            }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { myip in
                if !myip.isInvalidated {
                    self.ipAddressSubject.onNext(myip.userIp)
                }
            }).disposed(by: disposeBag)
    }

    var isBlurStaticIpAddress: Bool {
        return preferences.getBlurStaticIpAddress() ?? false
    }

    func markBlurStaticIpAddress(isBlured: Bool) {
        preferences.saveBlurStaticIpAddress(bool: isBlured)
    }

    func updateCardHeaderType(with headerType: CardHeaderButtonType) {
        cardHeaderTypeSubject.onNext(headerType)
    }
}
