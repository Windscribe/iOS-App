//
//  Combine+Extension.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/01/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Combine

/// Wraps a synchronous, non-throwing `Void`-returning function into a Combine-compatible `AnyPublisher`.
/// This is useful when integrating legacy imperative APIs into Combine pipelines without altering the original function.
func asVoidPublisher(_ action: @escaping () -> Void) -> AnyPublisher<Void, Error> {
    return Deferred {
        Future<Void, Error> { promise in
            // Execute the synchronous function
            action()
            // Immediately succeed with an empty value
            promise(.success(()))
        }
    }
    .eraseToAnyPublisher()
}
