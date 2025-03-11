//
//  NWInterface.InterfaceType+Ext.swift
//  Windscribe
//
//  Created by Bushra Sagir on 30/05/23.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Network

extension NWInterface.InterfaceType {
    var names: [String]? {
        switch self {
        case .wifi: return ["en0"]
        case .wiredEthernet: return ["en2", "en3", "en4"]
        case .cellular: return ["pdp_ip0", "pdp_ip1", "pdp_ip2", "pdp_ip3"]
        default: return nil
        }
    }

    func address(family: Int32) -> String? {
        guard let names = names else { return nil }
        var address: String?
        for name in names {
            guard let nameAddress = self.address(family: family, name: name) else { continue }
            address = nameAddress
            break
        }
        return address
    }

    func address(family: Int32, name: String) -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(family) {
                // Check interface name:
                if name == String(cString: interface.ifa_name) {
                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }

    var ipv4: String? { address(family: AF_INET) }
    var ipv6: String? { address(family: AF_INET6) }
}

extension String {
    var isRFC1918IPAddress: Bool {
        let rfc1918Ranges: [ClosedRange<UInt32>] = [
            0x0A00_0000 ... 0x0AFF_FFFF, // 10.0.0.0 - 10.255.255.255
            0xAC10_0000 ... 0xAC1F_FFFF, // 172.16.0.0 - 172.31.255.255
            0xC0A8_0000 ... 0xC0A8_FFFF  // 192.168.0.0 - 192.168.255.255
        ]
        if let ipAddressNumeric = ipToInt {
            for range in rfc1918Ranges where range.contains(UInt32(ipAddressNumeric)) {
                return true
            }
        }
        return false
    }

    var ipToInt: Int? {
        let octets: [Int] = split(separator: ".").map { Int($0)! }
        var numValue = 0
        for (i, n) in octets.enumerated() {
            let p: Int = NSDecimalNumber(decimal: pow(256, 3 - i)).intValue
            numValue += n * p
        }
        return numValue
    }
}
