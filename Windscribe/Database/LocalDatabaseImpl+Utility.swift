//
//  LocalDatabaseImpl+Utility.swift
//  Windscribe
//
//  Created by Andre Fonseca on 12/07/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import RxRealm
import RxSwift
import Realm

extension LocalDatabaseImpl {
    func getRealmObject<T: Object>(type: T.Type) -> T? {
        return try? Realm().objects(type).first
    }

    func getRealmObject<T: Object>(type: T.Type, primaryKey: String) -> T? {
        return try? Realm().object(ofType: type, forPrimaryKey: primaryKey)
    }

    func getRealmObjects<T: Object>(type: T.Type) -> [T]? {
        return try? Realm().objects(type).toArray()
    }

    func updateRealmObject<T: Object>(object: T) -> Disposable {
        return Observable.from(object: object)
            .subscribe(on: MainScheduler.asyncInstance).subscribe(onNext: { obj in
                let realm = try? Realm()
                try?realm?.safeWrite {
                    realm?.add(obj, update: .modified)
                }
            }, onError: { _ in})
    }

    func updateRealmObjects<T: Object>(objects: [T]) {
        DispatchQueue.main.async {
            let realm = try? Realm()
            try?realm?.safeWrite {
                objects.forEach { obj in
                    realm?.add(obj, update: .modified)
                }
            }
        }
    }

    func getSafeRealmObservable<T: Object>(type: T.Type) -> Observable<[T]> {
        return Observable.merge(cleanTrigger.asObservable().map { _ in return [T]() },
                                getRealmArrayObservable(type: T.self))
    }

    func getSafeRealmObservable<T: Object>(type: T.Type) -> Observable<T?> {
        return Observable.merge(cleanTrigger.asObservable().map { _ in return nil },
                                getRealmObservable(type: T.self).map { Optional($0) })
    }

    private func getRealmObservable<T: Object>(type: T.Type) -> Observable<T> {
        if let object = getRealmObject(type: type) {
            return Observable.from(object: object).catch { _ in
                return Observable.empty()
            }
        } else {
            return Observable.empty()
        }
    }

    // swiftlint:disable force_try
    private func getRealmArrayObservable<T: Object>(type: T.Type) -> Observable<[T]> {
        let realm = try! Realm()
        let objects = realm.objects(type.self)
        return Observable.changeset(from: objects)
            .filter { _ , changeset in
                guard let changeset = changeset else {
                    return true
                }
               return !changeset.deleted.isEmpty || !changeset.inserted.isEmpty || !changeset.updated.isEmpty
            }.map { results, _ in
                return AnyRealmCollection(results)
            }.catchAndReturn(AnyRealmCollection(try! Realm().objects(T.self)))
            .map { $0.toArray() }
    }
    // swiftlint:enable force_try

    func deleteRealmObject<T: Object>(object: T) {
        try? object.realm?.write {
            object.realm?.delete(object)
        }
    }

    func deleteRealmObject<T: Object>(objects: [T]) {
        let realm = try? Realm()
        try? realm?.safeWrite {
            realm?.delete(objects)
        }
    }
}
