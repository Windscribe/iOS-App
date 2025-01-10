//
//  Array.swift
//  Windscribe
//
//  Created by Yalcin on 2019-03-15.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

extension Array where Element: Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}

extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        var chunk: [Element] = []

        for element in self {
            chunk.append(element)
            if chunk.count == size {
                chunks.append(chunk)
                chunk = []
            }
        }

        if !chunk.isEmpty {
            chunks.append(chunk)
        }

        return chunks
    }
}
