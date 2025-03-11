//
//  RxRealm extensions
//
//  Copyright (c) 2016 RxSwiftCommunity. All rights reserved.
//  Check the LICENSE file for details
//  Created by Marin Todorov
//

import Foundation
import Realm
import RealmSwift
import RxSwift

public protocol NotificationEmitter {
    associatedtype ElementType: RealmCollectionValue

    func toAnyCollection() -> AnyRealmCollection<ElementType>
}

/**
 `RealmChangeset` is a struct that contains the data about a single realm change set.

 It includes the insertions, modifications, and deletions indexes in the data set that the current notification is about.
 */
public struct RealmChangeset {
    /// the indexes in the collection that were deleted
    public let deleted: [Int]

    /// the indexes in the collection that were inserted
    public let inserted: [Int]

    /// the indexes in the collection that were modified
    public let updated: [Int]
}

public enum RxRealmError: Error {
    case objectDeleted
    case unknown
}

extension List: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<Element>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

extension AnyRealmCollection: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

extension Results: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

extension LinkingObjects: NotificationEmitter {
    public func toAnyCollection() -> AnyRealmCollection<Element> {
        return AnyRealmCollection<ElementType>(self)
    }

    public typealias ElementType = Element
    public func toArray() -> [Element] {
        return Array(self)
    }
}

public extension Observable where Element: Object {
    /**
     Returns an `Observable<Object>` that emits each time the object changes. The observable emits an initial value upon subscription.

     - parameter object: A Realm Object to observe
     - parameter emitInitialValue: whether the resulting `Observable` should emit its first element synchronously (e.g. better for UI bindings)
     - parameter properties: changes to which properties would triger emitting a .next event
     - returns: `Observable<Object>` will emit any time the observed object changes + one initial emit upon subscription
     */

    static func from(object: Element, emitInitialValue: Bool = true,
                     properties: [String]? = nil) -> Observable<Element> {
        return Observable<Element>.create { observer in
            if emitInitialValue {
                observer.onNext(object)
            }

            let token = object.observe { change in
                switch change {
                case let .change(_, changedProperties):
                    if let properties = properties, !changedProperties.contains(where: { properties.contains($0.name) }) {
                        // if change property isn't an observed one, just return
                        return
                    }
                    observer.onNext(object)
                case .deleted:
                    observer.onError(RxRealmError.objectDeleted)
                case let .error(error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }
}

public extension ObservableType where Element: NotificationEmitter {
    /**
     Returns an `Observable<(Element, RealmChangeset?)>` that emits each time the collection data changes. The observable emits an initial value upon subscription.

     When the observable emits for the first time (if the initial notification is not coalesced with an update) the second tuple value will be `nil`.

     Each following emit will include a `RealmChangeset` with the indexes inserted, deleted or modified.

     - parameter from: A Realm collection of type `Element`: either `Results`, `List`, `LinkingObjects` or `AnyRealmCollection`.
     - parameter synchronousStart: whether the resulting Observable should emit its first element synchronously (e.g. better for UI bindings)
     - parameter queue: The serial dispatch queue to receive notification on. If `nil`, notifications are delivered to the current thread.

     - returns: `Observable<(AnyRealmCollection<Element.Element>, RealmChangeset?)>`
     */
    static func changeset(from collection: Element, synchronousStart: Bool = true, on queue: DispatchQueue? = nil)
    -> Observable<(AnyRealmCollection<Element.ElementType>, RealmChangeset?)> {
        return Observable.create { observer in
            if synchronousStart {
                observer.onNext((collection.toAnyCollection(), nil))
            }

            let token = collection.toAnyCollection().observe(on: queue) { changeset in

                switch changeset {
                case let .initial(value):
                    guard !synchronousStart else { return }
                    observer.onNext((value, nil))
                case let .update(value, deletes, inserts, updates):
                    observer.onNext((value, RealmChangeset(deleted: deletes, inserted: inserts, updated: updates)))
                case let .error(error):
                    observer.onError(error)
                    return
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }
}
