//
//  RxSwift+Extension.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Combine
import RxSwift

// MARK: RxSwift Bridge Error

enum RxBridgeError: Error {
    case missingInitialValue
}

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
        guard let initialValue = try? self.value() else {
            return Fail(outputType: Element.self, failure: RxBridgeError.missingInitialValue)
                .eraseToAnyPublisher()
        }

        let subject = CurrentValueSubject<Element, Error>(initialValue)

        let disposable = self.subscribe(
            onNext: {
                subject.send($0)
            },
            onError: {
                subject.send(completion: .failure($0))
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
