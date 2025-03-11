//
//  RXExtensions.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import RxSwift

extension PrimitiveSequence where Trait == SingleTrait {
    func asPublisher() -> AnyPublisher<Element, Error> {
        return Future { promise in
            _ = self.subscribe(
                onSuccess: { value in
                    promise(.success(value))
                },
                onFailure: { error in
                    promise(.failure(error))
                }
            )
        }
        .eraseToAnyPublisher()
    }
}

extension BehaviorSubject {
    func asPublisher() -> AnyPublisher<Element, Never> {
        return self
            .asObservable()
            .map { $0 } // Ensures type safety
            .catch { _ in Observable.empty() } // Prevents termination on error
            .toPublisher()
    }
}

extension Observable {
    func toPublisher() -> AnyPublisher<Element, Never> {
        let subject = PassthroughSubject<Element, Never>()

        let disposable = self.subscribe(
            onNext: { value in
                subject.send(value)
            },
            onError: { _ in
                subject.send(completion: .finished) // Ends gracefully on error
            },
            onCompleted: {
                subject.send(completion: .finished)
            }
        )

        return subject
            .handleEvents(receiveCancel: {
                disposable.dispose() // Clean up Rx subscription
            })
            .eraseToAnyPublisher()
    }
}

