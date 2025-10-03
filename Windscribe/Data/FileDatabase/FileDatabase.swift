//
//  FileDatabase.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum FileDatabaseError: Error, LocalizedError {
    case fileNotFound(String)
    case writeError(String)
    case deleteError(String)
    case directoryError(String)
    case invalidPath(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .writeError(let message):
            return "Failed to write file: \(message)"
        case .deleteError(let message):
            return "Failed to delete file: \(message)"
        case .directoryError(let message):
            return "Directory access error: \(message)"
        case .invalidPath(let path):
            return "Invalid file path: \(path)"
        }
    }
}

protocol FileDatabase {
    func readFile(path: String) async throws -> Data
    func saveFile(data: Data, path: String) async throws
    func removeFile(path: String) async throws
}
