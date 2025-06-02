//
//  Task+Extension.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

extension Task where Success == Void, Failure == Never {
    static func delayed(_ seconds: TimeInterval, execute work: @escaping @MainActor () -> Void) {
        Task {
            let nanoseconds = UInt64(seconds * 1_000_000_000)
            try? await Task<Never, Never>.sleep(nanoseconds: nanoseconds)
            await MainActor.run {
                work()
            }
        }
    }
}
