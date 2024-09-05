//
//  FileLogger.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-03.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import CocoaLumberjack
import Foundation
import RxSwift
protocol FileLogger {
    var logDirectory: URL? { get set}
    func logDeviceInfo()
    func getLogData() -> Single<String>
    func logD(_ tag: Any, _ message: String)
    func logI(_ tag: Any, _ message: String)
    func logE(_ tag: Any, _ message: String)
}
