//
//  LocalDatabaseImpl+Utility.swift
//  Windscribe
//
//  Created by Andre Fonseca on 12/07/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import RxSwift

extension LocalDatabaseImpl {
    func getRealmObject<T: Object>(type: T.Type) -> T? {
        do {
            let realm = try Realm()
            return realm.objects(type).first
        } catch let error {
            logger.logE("LocalDatabaseImpl", "Getting Realm was not possible, with error \(error.localizedDescription)")
            return nil
        }
    }

    func getRealmObject<T: Object>(type: T.Type, primaryKey: String) -> T? {
        return try? Realm().object(ofType: type, forPrimaryKey: primaryKey)
    }

    func getRealmObjects<T: Object>(type: T.Type) -> [T]? {
        return try? Array(Realm().objects(type))
    }

    func updateRealmObject<T: Object>(object: T) -> Disposable {
        // Check if the object is already managed by Realm
        if let realm = object.realm {
            return Observable.from(object: object)
                .take(1)
                .subscribe(on: MainScheduler.asyncInstance)
                .subscribe(onNext: { obj in
                    DispatchQueue.main.async {
                        do {
                            if !obj.isInvalidated {
                                try realm.safeWrite {
                                    realm.add(obj, update: .modified)
                                }
                            } else {
                                print("Realm object is invalidated and cannot be updated.")
                            }
                        } catch {
                            print("Error updating Realm object: \(error.localizedDescription)")
                        }
                    }
                }, onError: { error in
                    print("Error in Observable: \(error.localizedDescription)")
                })
        } else {
            DispatchQueue.main.async {
                do {
                    let realm = try Realm()
                    try realm.safeWrite {
                        realm.add(object, update: .modified)
                    }
                } catch {
                    print("Error adding object to Realm: \(error.localizedDescription)")
                }
            }
            return Disposables.create()
        }
    }

    func updateRealmObjects<T: Object>(objects: [T]) {
        DispatchQueue.main.async {
            let realm = try? Realm()
            try? realm?.safeWrite {
                for obj in objects {
                    realm?.add(obj, update: .modified)
                }
            }
        }
    }

    func getSafeRealmObservable<T: Object>(type: T.Type) -> Observable<[T]> {
        return Observable.merge(cleanTrigger.asObservable().map { _ in [T]() },
                                getRealmArrayObservable(type: T.self))
    }

    func getSafeRealmObservable<T: Object>(type: T.Type) -> Observable<T?> {
        return Observable.merge(cleanTrigger.asObservable().map { _ in nil },
                                getRealmObservable(type: T.self).map { Optional($0) })
    }

    private func getRealmObservable<T: Object>(type: T.Type) -> Observable<T> {
        if let object = getRealmObject(type: type) {
            return Observable.from(object: object).catch { _ in
                Observable.empty()
            }
        } else {
            return Observable.empty()
        }
    }

    private func getRealmArrayObservable<T: Object>(type: T.Type) -> Observable<[T]> {
        let realm: Realm
        do {
            realm = try Realm()
        } catch {
            return Observable.just([])
        }
        let objects = realm.objects(type.self)
        return Observable.changeset(from: objects)
            .filter { _, changeset in
                guard let changeset = changeset else {
                    return true
                }
                return !changeset.deleted.isEmpty || !changeset.inserted.isEmpty || !changeset.updated.isEmpty
            }
            .map { results, _ in
                guard !results.isInvalidated else { return [] }
                return Array(results)
            }
            .catch { _ in
                Observable.just((try? Array(Realm().objects(T.self))) ?? [])
            }
            .subscribe(on: MainScheduler.instance)
            .observe(on: MainScheduler.instance)
    }

    func deleteRealmObject<T: Object>(object: T) {
        let realm = try? Realm()
        try? realm?.safeWrite {
            realm?.delete(object)
        }
    }

    func deleteRealmObject<T: Object>(objects: [T]) {
        let realm = try? Realm()
        try? realm?.safeWrite {
            realm?.delete(objects)
        }
    }
}
