//
//  FileDatabase.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol FileDatabase {
    func readFile(path: String) -> Data?
    func saveFile(data: Data, path: String)
    func removeFile(path: String)
}
