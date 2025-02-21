//
//  MockLogger.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

@testable import Windscribe

class MockLogger: FileLogger {
    var logDirectory: URL?

    func logDeviceInfo() {}

    func getLogData() -> RxSwift.Single<String> {
        Single.just("Test Logs")
    }

    func logI(_ tag: Any, _ message: String) {}

    func logE(_ tag: Any, _ message: String) {}

    func logD(_ object: Any, _ message: String) {
        print("[MOCK LOGGER] \(message)")
    }
}
