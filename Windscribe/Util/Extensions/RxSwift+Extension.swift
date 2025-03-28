//
//  RXExtensions.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import RxSwift

// MARK: Single -> Combine

extension PrimitiveSequence where Trait == SingleTrait {
    func asPublisher() -> AnyPublisher<Element, Error> {
        return Deferred {
            Future { promise in
                let disposable = self.subscribe(
                    onSuccess: { value in
                        promise(.success(value))
                    },
                    onFailure: { error in
                        promise(.failure(error))
                    }
                )

                _ = disposable
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: BehaviorSubject -> Combine (with error propagation)

extension BehaviorSubject {
    func asPublisher() -> AnyPublisher<Element, Error> {
        return self
            .asObservable()
            .toPublisher()
    }
}

// MARK: Observable -> Combine (with error propagation)

extension Observable {
    func toPublisher() -> AnyPublisher<Element, Error> {
        let subject = PassthroughSubject<Element, Error>()
        let disposable = self.subscribe(
            onNext: { value in
                subject.send(value)
            },
            onError: { error in
                subject.send(completion: .failure(error))
            },
            onCompleted: {
                subject.send(completion: .finished)
            }
        )

        return subject
            .handleEvents(receiveCancel: {
                disposable.dispose()
            })
            .eraseToAnyPublisher()
    }
}
