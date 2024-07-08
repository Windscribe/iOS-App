//
//  DNSSettingsManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 04/07/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

protocol OpensURlType {
    func canOpenURL(_ url: URL) -> Bool
}

struct DNSSettingsManager {
    static func makeDNSSettings(from dnsValue: DNSValue) -> NEDNSSettings? {
        guard #available(iOS 14.0, *), !dnsValue.value.isEmpty else { return nil }
        switch dnsValue.type {
        case .ipAddress:
            let settings = NEDNSSettings(servers: dnsValue.servers)
            return settings
        case .overHttps:
            let settings = NEDNSOverHTTPSSettings(servers: dnsValue.servers)
            guard let url = URL(string: dnsValue.value) else { return nil }
            settings.serverURL = url
            return settings
        case .overTLS:
            let settings = NEDNSOverTLSSettings(servers: dnsValue.servers)
            settings.serverName = dnsValue.value
            return settings
        default:
            return nil
        }
    }

    static func getDNSValue(from value: String, opensURL: OpensURlType,
                            completionDNS: @escaping (_ dnsValue: DNSValue?) -> Void,
                            completion: @escaping (_ isValid: Bool) -> Void) {

        if IPv4Address(value) != nil || IPv6Address(value) != nil {
            completion(true)
            DispatchQueue.global().async {
                completionDNS(DNSValue(type: .ipAddress, value: value, servers: [value]))
            }
            return
        } else if let url = URL(string: value) {
            if opensURL.canOpenURL(url), value.contains("https://") {
                completion(true)
                DispatchQueue.global().async {
                    completionDNS(DNSValue(type: .overHttps, value: value,
                                           servers: DNSSettingsManager.resolveHosts(fromURL: value)))
                }
                return
            } else if let editedURL = URL(string: "https://\(value)"), opensURL.canOpenURL(editedURL) {
                completion(true)
                DispatchQueue.global().async {
                    completionDNS(DNSValue(type: .overTLS, value: value,
                                           servers: DNSSettingsManager.resolveHosts(for: value)))
                }
                return
            }
        }
        completion(true)
        completionDNS(nil)
    }

    private static func resolveHosts(fromURL urlValue: String) -> [String] {
        guard let url = URL(string: urlValue),
              let hostname = url.host
        else { return [] }
        return DNSSettingsManager.resolveHosts(for: hostname)
    }

    private static func resolveHosts(for hostname: String) -> [String] {
        var hints = addrinfo(
            ai_flags: 0,
            ai_family: AF_UNSPEC,
            ai_socktype: SOCK_STREAM,
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )
        var info: UnsafeMutablePointer<addrinfo>?
        let result = getaddrinfo(hostname, nil, &hints, &info)
        if result != 0 {
            if let errorMessage = gai_strerror(result) {
                print("$$$ Error resolving DNS: \(String(cString: errorMessage))")
            }
            return []
        }
        var currentInfo = info
        var returnHosts = [String]()
        while currentInfo != nil {
            if let address = currentInfo?.pointee.ai_addr {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(address, socklen_t(currentInfo!.pointee.ai_addrlen), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    returnHosts.append(String(cString: host))
                }
            }
            currentInfo = currentInfo?.pointee.ai_next
        }
        freeaddrinfo(info)
        return returnHosts
    }
}

enum ConnectedDNSType {
    case auto
    case custom

    static func defaultValue() -> ConnectedDNSType { ConnectedDNSType() }

    init() {
       self = .auto
    }

    init(value: String) {
        self = switch value {
        case "Auto":
                .auto
        case "Custom":
                .custom
        default:
                .auto
        }
    }
}
