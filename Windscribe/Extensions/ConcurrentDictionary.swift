//
//  ConcurrentDictionary.swift
//  Windscribe
//
//  Created by Ginder Singh on 2022-12-21.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
/// Simple thread safe generic dictionary
/// K type of Key
/// V type of Value
class ConcurrentDictionary<K: Hashable, V> {
    /// Back up dictionary to hold data
    private var dictionary: [K: V] = [:]
    /// Dispatch queue controls access to the data
    private let accessQueue = DispatchQueue(label: "Concurrent access queue", attributes: .concurrent)
    subscript(key: K) -> V? {
        get {
            self.accessQueue.sync {
                return dictionary[key]
            }
        }
        set(newValue) {
            self.accessQueue.async(flags: .barrier) { [weak self] in
                self?.dictionary[key] = newValue
            }
        }
    }
}
