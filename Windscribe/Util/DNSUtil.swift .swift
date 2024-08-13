//
//  DNSUtil.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-07-28.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
func setWSNetDNSServer(servers: [String], force: Bool = false) {
    if Resolver().getservers().isEmpty || force {
        WSNet.instance().dnsResolver().setDnsServers(servers)
    } else {
        WSNet.instance().dnsResolver().setDnsServers(Resolver().getservers().map {Resolver.getnameinfo($0)})
    }
}
