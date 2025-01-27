//
//  DNSUtil.swift .swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-07-28.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

func setWSNetDNSServer(servers: [String], ext: Bool = false) {
    if Resolver().getservers().isEmpty {
        WSNet.instance().dnsResolver().setDnsServers(servers)
    } else if ext {
        WSNet.instance().dnsResolver().setDnsServers(["76.76.2.0", "1.1.1.1", "9.9.9.9"])
    } else {
        WSNet.instance().dnsResolver().setDnsServers(Resolver().getservers().map { Resolver.getnameinfo($0) })
    }
}
