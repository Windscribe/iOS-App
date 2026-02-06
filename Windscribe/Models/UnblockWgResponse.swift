//
//  UnblockWgResponse.swift
//  Windscribe
//
//  Created by Ginder Singh on 2026-01-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct UnblockWgResponse: Decodable {
    let params: [UnblockWgParams]

    enum CodingKeys: String, CodingKey {
        case data
        case params
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        params = try data.decodeIfPresent([UnblockWgParams].self, forKey: .params) ?? []
    }
}

struct UnblockWgParams: Codable {
    let title: String
    let countries: [String]
    let jc: Int?
    let jMin: Int?
    let jMax: Int?
    let s1: Int?
    let s2: Int?
    let s3: Int?
    let s4: Int?
    let h1: String?
    let h2: String?
    let h3: String?
    let h4: String?
    let i1: String?
    let i2: String?
    let i3: String?
    let i4: String?
    let i5: String?

    enum CodingKeys: String, CodingKey {
        case title
        case countries
        case jc = "Jc"
        case jMin = "Jmin"
        case jMax = "Jmax"
        case s1 = "S1"
        case s2 = "S2"
        case s3 = "S3"
        case s4 = "S4"
        case h1 = "H1"
        case h2 = "H2"
        case h3 = "H3"
        case h4 = "H4"
        case i1 = "I1"
        case i2 = "I2"
        case i3 = "I3"
        case i4 = "I4"
        case i5 = "I5"
    }

    init(from: UnblockWgParamsObj) {
        title = from.title
        countries = Array(from.countries)
        jc = from.jc
        jMin = from.jMin
        jMax = from.jMax
        s1 = from.s1
        s2 = from.s2
        s3 = from.s3
        s4 = from.s4
        h1 = from.h1
        h2 = from.h2
        h3 = from.h3
        h4 = from.h4
        i1 = from.i1
        i2 = from.i2
        i3 = from.i3
        i4 = from.i4
        i5 = from.i5
    }

    func getObject() -> UnblockWgParamsObj {
        .init(from: self)
    }

    func getConfigText() -> String {
        var output = ""

        if  let jc = jc {
            output.append("\(CodingKeys.jc.stringValue) = \(jc)\n")
        }
        if  let jMin = jMin {
            output.append("\(CodingKeys.jMin.stringValue) = \(jMin)\n")
        }
        if  let jMax = jMax {
            output.append("\(CodingKeys.jMax.stringValue) = \(jMax)\n")
        }
        if  let s1 = s1 {
            output.append("\(CodingKeys.s1.stringValue) = \(s1)\n")
        }
        if  let s2 = s2 {
            output.append("\(CodingKeys.s2.stringValue) = \(s2)\n")
        }
        if  let s3 = s3 {
            output.append("\(CodingKeys.s3.stringValue) = \(s3)\n")
        }
        if  let s4 = s4 {
            output.append("\(CodingKeys.s4.stringValue) = \(s4)\n")
        }
        if  let h1 = h1 {
            output.append("\(CodingKeys.h1.stringValue) = \(h1)\n")
        }
        if  let h2 = h2 {
            output.append("\(CodingKeys.h2.stringValue) = \(h2)\n")
        }
        if  let h3 = h3 {
            output.append("\(CodingKeys.h3.stringValue) = \(h3)\n")
        }
        if  let h4 = h4 {
            output.append("\(CodingKeys.h4.stringValue) = \(h4)\n")
        }
        if  let i1 = i1, !i1.isEmpty {
            output.append("\(CodingKeys.i1.stringValue) = \(i1)\n")
        }
        if  let i2 = i2, !i2.isEmpty {
            output.append("\(CodingKeys.i2.stringValue) = \(i2)\n")
        }
        if  let i3 = i3, !i3.isEmpty {
            output.append("\(CodingKeys.i3.stringValue) = \(i3)\n")
        }
        if  let i4 = i4, !i4.isEmpty {
            output.append("\(CodingKeys.i4.stringValue) = \(i4)\n")
        }

        return output
    }
}

@objcMembers class UnblockWgParamsObj: Object {
    @Persisted(primaryKey: true) dynamic var title: String = ""
    dynamic var countries = List<String>()
    dynamic var jc: Int?
    dynamic var jMin: Int?
    dynamic var jMax: Int?
    dynamic var s1: Int?
    dynamic var s2: Int?
    dynamic var s3: Int?
    dynamic var s4: Int?
    dynamic var h1: String?
    dynamic var h2: String?
    dynamic var h3: String?
    dynamic var h4: String?
    dynamic var i1: String?
    dynamic var i2: String?
    dynamic var i3: String?
    dynamic var i4: String?
    dynamic var i5: String?

    required convenience init(from: UnblockWgParams) {
        self.init()

        title = from.title
        setCountries(array: from.countries)
        jc = from.jc
        jMin = from.jMin
        jMax = from.jMax
        s1 = from.s1
        s2 = from.s2
        s3 = from.s3
        s4 = from.s4
        h1 = from.h1
        h2 = from.h2
        h3 = from.h3
        h4 = from.h4
        i1 = from.i1
        i2 = from.i2
        i3 = from.i3
        i4 = from.i4
        i5 = from.i5
    }

    func setCountries(array: [String]) {
        countries.removeAll()
        countries.append(objectsIn: array)
    }

    func getModel() -> UnblockWgParams {
        .init(from: self)
    }
}
