//
//  Data+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-04-22.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

extension Data {
    func append(to url: URL, offset: Int) throws {
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seek(toFileOffset: UInt64(offset))
            fileHandle.write(self)
        } else {
            try write(to: url)
        }
    }
}

extension Bool {

    var data: Data {
        var value = self
        let nsdata =  NSData(bytes: &value, length: MemoryLayout.size(ofValue: self))
        return Data(referencing: nsdata)
    }

    init?(data: NSData) {
        guard data.length == 1 else { return nil }
        var value = false
        data.getBytes(&value, length: MemoryLayout<Bool>.size)
        self = value
    }
}
