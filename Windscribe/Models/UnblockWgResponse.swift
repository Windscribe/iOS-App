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

    // Memberwise initializer for testing
    init(params: [UnblockWgParams]) {
        self.params = params
    }
}

struct UnblockWgParams: Codable, Equatable {
    let id: String
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
        case id
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

    init(id: String, title: String, countries: [String],
         jc: Int?, jMin: Int?, jMax: Int?,
         s1: Int?, s2: Int?, s3: Int?, s4: Int?,
         h1: String?, h2: String?, h3: String?, h4: String?,
         i1: String?, i2: String?, i3: String?, i4: String?, i5: String?) {
        self.id = id
        self.title = title
        self.countries = countries
        self.jc = jc
        self.jMin = jMin
        self.jMax = jMax
        self.s1 = s1
        self.s2 = s2
        self.s3 = s3
        self.s4 = s4
        self.h1 = h1
        self.h2 = h2
        self.h3 = h3
        self.h4 = h4
        self.i1 = i1
        self.i2 = i2
        self.i3 = i3
        self.i4 = i4
        self.i5 = i5
    }

    init(from: UnblockWgParamsObj) {
        id = from.id
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

    func getConfigText() -> [String] {
        var output = [String]()
        if  let jc = jc, jc != 0 {
            output.append("jc = \(jc)")
        }
        if  let jMin = jMin, jMin != 0 {
            output.append("jmin = \(jMin)")
        }
        if  let jMax = jMax, jMax != 0 {
            output.append("jmax = \(jMax)")
        }
        if  let s1 = s1, s1 != 0 {
            output.append("s1 = \(s1)")
        }
        if  let s2 = s2, s2 != 0 {
            output.append("s2 = \(s2)")
        }
        if  let s3 = s3, s3 != 0 {
            output.append("s3 = \(s3)")
        }
        if  let s4 = s4, s4 != 0 {
            output.append("s4 = \(s4)")
        }
        if  let h1 = h1, !h1.isEmpty {
            output.append("h1 = \(h1)")
        }
        if  let h2 = h2, !h2.isEmpty {
            output.append("h2 = \(h2)")
        }
        if  let h3 = h3, !h3.isEmpty {
            output.append("h3 = \(h3)")
        }
        if  let h4 = h4, !h4.isEmpty {
            output.append("h4 = \(h4)")
        }
        if  let i1 = i1, !i1.isEmpty {
            output.append("i1 = \(i1)")
        }
        if  let i2 = i2, !i2.isEmpty {
            output.append("i2 = \(i2)")
        }
        if  let i3 = i3, !i3.isEmpty {
            output.append("i3 = \(i3)")
        }
        if  let i4 = i4, !i4.isEmpty {
            output.append("i4 = \(i4)")
        }
        if  let i5 = i5, !i5.isEmpty {
            output.append("i5 = \(i5)")
        }
        return output
    }
}

@objcMembers class UnblockWgParamsObj: Object {
    dynamic var id: String = ""
    dynamic var title: String = ""
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

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(from: UnblockWgParams) {
        self.init()

        id = from.id
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
