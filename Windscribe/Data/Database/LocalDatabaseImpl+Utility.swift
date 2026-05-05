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
import Combine

extension LocalDatabaseImpl {
    private func getRealm<T: Object>(object: T) throws -> Realm {
        if let realm = object.realm {
            return realm
        }
        return try Realm()
    }

    private func writeObject<T: Object>(object: T, realm: Realm) throws {
        // Check if the object is already managed by Realm
        if !object.isInvalidated {
            try realm.safeWrite {
                realm.add(object, update: .modified)
            }
        } else {
            print("Realm object is invalidated and cannot be updated.")
        }
    }

    func getRealmObject<T: Object>(type: T.Type, primaryKey: String) -> T? {
        do {
            let realm = try Realm()
            return realm.object(ofType: type, forPrimaryKey: primaryKey)
        } catch {
            logger.logE("LocalDatabaseImpl", "Getting Realm was not possible, with error \(error.localizedDescription)")
            return nil
        }
    }

    func getRealmObject<T: Object>(type: T.Type) -> T? {
        getRealmObjectList(type: type)?.first
    }

    func getRealmObjectList<T: Object>(type: T.Type) -> [T]? {
        do {
            let realm = try Realm()
            let results = realm.objects(type)
            return Array(results)
        } catch {
            logger.logE("LocalDatabaseImpl", "Getting Realm was not possible, with error \(error.localizedDescription)")
            return nil
        }
    }

    func updateRealmObject<T: Object>(object: T) {
        do {
            let realm = try getRealm(object: object)
            try writeObject(object: object, realm: realm)
        } catch {
            print("Error updating Realm object: \(error.localizedDescription)")
        }
    }

    func updateRealmObjects<T: Object>(objects: [T]) {
        do {
            let realm = try Realm()
            try realm.safeWrite {
                for obj in objects {
                    realm.add(obj, update: .modified)
                }
            }
        } catch {
            print("Error updating Realm object list: \(error.localizedDescription)")
        }
    }

    func deleteRealmObject<T: Object>(object: T) {
        do {
            let realm = try getRealm(object: object)
            try realm.safeWrite {
                realm.delete(object)
            }
        } catch {
            print("Error deleting Realm object: \(error.localizedDescription)")
        }
    }

    func deleteRealmObject<T: Object>(objects: [T]) {
        do {
            let realm = try Realm()
            try realm.safeWrite {
                realm.delete(objects)
            }
        } catch {
            print("Error deleting Realm object list: \(error.localizedDescription)")
        }
    }

    // MARK: - Combine Equivalents
    func getSafeRealmObjectPublisher<T: Object>(type: T.Type) -> AnyPublisher<T?, Never> {
        let cleanPublisher = cleanSubject
            .map { _ in nil as T? }
            .eraseToAnyPublisher()
        let realmPublisher = getRealmObjectPublisher(type: T.self)

        return Publishers.Merge(cleanPublisher, realmPublisher)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    func getSafeRealmArrayPublisher<T: Object>(type: T.Type) -> AnyPublisher<[T], Never> {
        let cleanPublisher = cleanSubject
            .map { _ in [T]() }
            .eraseToAnyPublisher()
        let realmPublisher = getRealmArrayPublisher(type: T.self)

        return Publishers.Merge(cleanPublisher, realmPublisher)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    // MARK: - Model Publisher Helpers

    /// Returns a publisher that emits a mapped domain model (or nil) whenever the first
    /// Realm object of `type` changes.
    func getModelObjectPublisher<R: Object, M>(type: R.Type,
                                               convert: @escaping (R) -> M) -> AnyPublisher<M?, Never> {
        let cleanPublisher = cleanSubject
            .map { _ in nil as M? }
            .eraseToAnyPublisher()
        let realmPublisher = getRealmObjectPublisher(type: R.self)
            .map { $0.map(convert) }
            .eraseToAnyPublisher()

        return Publishers.Merge(cleanPublisher, realmPublisher)
            .eraseToAnyPublisher()
    }

    /// Returns a publisher that emits a mapped array of domain models whenever the
    /// Realm collection of `type` changes.
    func getModelArrayPublisher<R: Object, M>(type: R.Type,
                                              convert: @escaping (R) -> M) -> AnyPublisher<[M], Never> {
        let cleanPublisher = cleanSubject
            .map { _ in [M]() }
            .eraseToAnyPublisher()
        let realmPublisher = getRealmArrayPublisher(type: R.self)
            .map { $0.map(convert) }
            .eraseToAnyPublisher()

        return Publishers.Merge(cleanPublisher, realmPublisher)
            .eraseToAnyPublisher()
    }

    private func getRealmObjectPublisher<T: Object>(type: T.Type) -> AnyPublisher<T?, Never> {
        do {
            let realm = try Realm()
            let objects = realm.objects(type.self)

            return objects.collectionPublisher
                .map { results -> T? in
                    guard !results.isInvalidated else { return nil }
                    return results.first
                }
                .replaceError(with: nil)
                .eraseToAnyPublisher()

        } catch {
            return Just(nil)
                .eraseToAnyPublisher()
        }
    }

    private func getRealmArrayPublisher<T: Object>(type: T.Type) -> AnyPublisher<[T], Never> {
        do {
            let realm = try Realm()
            let objects = realm.objects(type.self)

            return objects.collectionPublisher
                .map { results in
                    guard !results.isInvalidated else { return [] }
                    return Array(results)
                }
                .replaceError(with: [])
                .eraseToAnyPublisher()

        } catch {
            // If Realm init fails, return an empty publisher
            return Just<[T]>([])
                .eraseToAnyPublisher()
        }
    }
}
