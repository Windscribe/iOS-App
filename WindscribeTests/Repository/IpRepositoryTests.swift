//
//  IpRepositoryTests.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-27.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Mockingbird
import RxSwift
@testable import Windscribe
import XCTest
class IpRepositoryTests: XCTestCase {
    let disposeBag = DisposeBag()

    func testIpUpdate() {
//        let myIp = mapToSuccess(json: myIPSuccessJson, modeType: MyIP.self)!
//        let api = mock(APIManager.self)
//        given(api.getIp()).willReturn(Single.just(myIp))
//
//        let db = mock(LocalDatabase.self)
//        given(db.getIp()).willReturn(Observable.empty())
//        given(db.saveIp(myip: myIp)).willReturn(Disposables.create())
//
//        let ipRepository = IPRepositoryImpl(apiManager: api, localDatabase: db, logger: FileLoggerImpl())
//        let expection1 = expectation(description: "wait for get ip call.")
//        ipRepository.getIp().subscribe(onSuccess: { data in
//            XCTAssertTrue(data.userIp == myIp.userIp)
//            expection1.fulfill()
//        }, onFailure: { error in
//            XCTFail(error.localizedDescription)
//            expection1.fulfill()
//        }).disposed(by: disposeBag)
//        waitForExpectations(timeout: 2) { error in
//            if let error = error {
//                XCTFail(error.localizedDescription)
//            }
//        }
    }
}
