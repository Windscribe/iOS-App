//
//  StaticIpRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol StaticIpRepository {
    var staticIPs: [StaticIPModel] { get }
    func updateStaticServers() async throws
    func getStaticIp(id: Int) -> StaticIPModel?
}
