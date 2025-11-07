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
                if let array = value as? [Any], array.isEmpty {
                    return
                }
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

    func toPublisherIncludingEmpty() -> AnyPublisher<Element, Error> {
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

        func toInitialPublisher() -> AnyPublisher<Element, Error> {
            return Deferred {
                Future { promise in
                    let disposable = self.subscribe(
                        onNext: { value in
                            promise(.success(value))
                        },
                        onError: { error in
                            promise(.failure(error))
                        }
                    )
                    _ = disposable
                }
            }
            .eraseToAnyPublisher()
        }

}

// MARK: Observable Initial Value -> Combine (with error propagation)

extension ObservableType {

    /// Converts Observable to Combine Publisher without initial value (cold start).
    func toPublisher() -> AnyPublisher<Element, Error> {
        let subject = PassthroughSubject<Element, Error>()
        let disposable = self.subscribe(
            onNext: { subject.send($0) },
            onError: { subject.send(completion: .failure($0)) },
            onCompleted: { subject.send(completion: .finished) }
        )

        return subject
            .handleEvents(receiveCancel: {
                disposable.dispose()
            })
            .eraseToAnyPublisher()
    }

    /// Converts Observable to Combine Publisher and immediately emits the given initial value.
    func toPublisher(initialValue: Element) -> AnyPublisher<Element, Error> {
        let subject = CurrentValueSubject<Element, Error>(initialValue)
        let disposable = self.subscribe(
            onNext: { subject.send($0) },
            onError: { subject.send(completion: .failure($0)) },
            onCompleted: { subject.send(completion: .finished) }
        )

        return subject
            .handleEvents(receiveCancel: {
                disposable.dispose()
            })
            .eraseToAnyPublisher()
    }
}

// MARK: Async/Await -> RxSwift Bridge

/// Converts an async throwing function to RxSwift Single
func asyncToSingle<T>(_ operation: @escaping () async throws -> T) -> Single<T> {
    return Single.create { single in
        let task = Task {
            do {
                let result = try await operation()
                single(.success(result))
            } catch {
                single(.failure(error))
            }
        }

        return Disposables.create {
            task.cancel()
        }
    }
}

// MARK: Utility Publisher for Synchronous Void-Returning Functions

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
