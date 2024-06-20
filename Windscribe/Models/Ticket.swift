//
//  TicketResponse.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-06-26.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation

@objcMembers class Ticket: Decodable {
    var ticket: String = ""
    var status: String = ""

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case ticket = "ticket_id"
        case status = "status"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        ticket = try data.decodeIfPresent(String.self, forKey: .ticket) ?? ""
        status = try data.decodeIfPresent(String.self, forKey: .status) ?? ""
    }
}
