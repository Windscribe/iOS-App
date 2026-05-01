//
//  PreferencesImpl+Utils.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/04/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//


import Combine

// MARK: Utility Methods

extension PreferencesImpl {

    // Generic Combine Helpers

    func observeKey<T: Equatable>(_ key: String, type: T.Type, defaultValue: T?) -> AnyPublisher<T?, Never> {
        guard let sharedDefault = sharedDefault else {
            return Just(defaultValue).eraseToAnyPublisher()
        }

        return sharedDefault.publisher(for: key, type: type)
            .map { $0 ?? defaultValue }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func observeKeyEmpty<T: Equatable>(_ key: String, type: T.Type) -> AnyPublisher<T?, Never> {
        guard let sharedDefault = sharedDefault else {
            return Empty().eraseToAnyPublisher()
        }

        return sharedDefault.publisher(for: key, type: type)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func observeKeyNonOptional<T: Equatable>(_ key: String, type: T.Type, defaultValue: T, transform: @escaping (T?) -> T) -> AnyPublisher<T, Never> {
        guard let sharedDefault = sharedDefault else {
            return Just(defaultValue).eraseToAnyPublisher()
        }

        return sharedDefault.publisher(for: key, type: type)
            .map(transform)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func getString(forKey: String) -> String? {
        return sharedDefault?.string(forKey: forKey)
    }

    func setString(_ value: String?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    // Synchronous getters for tvOS preferences display
    func getOrderLocationsBySync() -> String? {
        return getString(forKey: SharedKeys.orderLocationsBy)
    }

    func getSelectedProtocolSync() -> String? {
        return getString(forKey: SharedKeys.selectedProtocol)
    }

    func getSelectedPortSync() -> String? {
        return getString(forKey: SharedKeys.port)
    }

    func getBool(key: String) -> Bool {
        return sharedDefault?.bool(forKey: key) ?? false
    }

    func setBool(_ value: Bool?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getInt(forKey: String) -> Int? {
        return sharedDefault?.integer(forKey: forKey)
    }

    func setInt(_ value: Int?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getInt64(forKey: String) -> Int64? {
        return (sharedDefault?.object(forKey: forKey) as? NSNumber)?.int64Value
    }

    func setInt64(_ value: Int64?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getDate(forKey: String) -> Date? {
        guard let date = sharedDefault?.object(forKey: forKey) as? Date else { return nil }
        return date
    }

    func setDate(_: Any?, forKey: String) {
        sharedDefault?.set(Date(), forKey: forKey)
    }

    func getDouble(forKey: String) -> Double? {
        return sharedDefault?.double(forKey: forKey)
    }

    func setDouble(_ value: Double?, forKey: String) {
        sharedDefault?.setValue(value, forKey: forKey)
    }

    func getData(key: String) -> Any? {
        return sharedDefault?.value(forKey: key)
    }

    func saveData(value: Any, key: String) {
        sharedDefault?.setValue(value, forKey: key)
    }

    func removeData(key: String) {
        sharedDefault?.removeObject(forKey: key)
    }

    func saveObject<T: Codable>(object: T, forKey: String) {
        do {
            let data = try JSONEncoder().encode(object)
            sharedDefault?.set(data, forKey: forKey)
        } catch {
            logger.logE("PreferencesImpl", "Failed to save object for key \(forKey): \(error.localizedDescription)")
        }
    }

    func getObject<T: Codable>(forKey: String) -> T? {
        guard let data = sharedDefault?.data(forKey: forKey) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            logger.logE("PreferencesImpl", "Failed to decode object for key \(forKey): \(error.localizedDescription)")
            return nil
        }
    }

    func removeObjects(forKey: [String]) {
        for key in forKey {
            sharedDefault?.removeObject(forKey: key)
        }
    }
}
