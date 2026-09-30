//
//  LogMessagePolicy.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

struct LogMessagePolicy: Sendable {
    // MARK: - Properties

    static let truncationMarker = " … [truncated]"

    // MARK: - Internal Methods

    func normalize(_ message: String, fitting maximumBytes: Int) -> String {
        guard maximumBytes > 0 else { return "" }

        var result = ""
        var resultBytes = 0
        var lineCount = 1
        var previousWasCarriageReturn = false
        var wasTruncated = false

        for scalar in message.unicodeScalars {
            if scalar.value == 13 { // \r
                if lineCount >= 2 || resultBytes + 1 > maximumBytes {
                    wasTruncated = true
                    break
                }
                result.append("\n")
                resultBytes += 1
                lineCount += 1
                previousWasCarriageReturn = true
                continue
            }

            if scalar.value == 10 { // \n
                if previousWasCarriageReturn {
                    previousWasCarriageReturn = false
                    continue
                }
                if lineCount >= 2 || resultBytes + 1 > maximumBytes {
                    wasTruncated = true
                    break
                }
                result.append("\n")
                resultBytes += 1
                lineCount += 1
                continue
            }

            previousWasCarriageReturn = false
            let scalarString = String(scalar)
            let scalarBytes = scalarString.utf8.count
            if resultBytes + scalarBytes > maximumBytes {
                wasTruncated = true
                break
            }
            result.append(scalarString)
            resultBytes += scalarBytes
        }

        guard wasTruncated else { return result }

        let marker = Self.truncationMarker
        let markerBytes = marker.utf8.count
        guard markerBytes <= maximumBytes else {
            return truncateUTF8(marker, to: maximumBytes)
        }

        return truncateUTF8(result, to: maximumBytes - markerBytes) + marker
    }

    // MARK: - Private Methods

    private func truncateUTF8(_ value: String, to maximumBytes: Int) -> String {
        guard maximumBytes > 0 else { return "" }
        guard value.utf8.count > maximumBytes else { return value }

        let prefix = Array(value.utf8.prefix(maximumBytes))
        var validLength = prefix.count
        while validLength > 0 {
            if let result = String(bytes: prefix.prefix(validLength), encoding: .utf8) {
                return result
            }
            validLength -= 1
        }
        return ""
    }
}
