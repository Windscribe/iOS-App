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
        let customValue = value.lowercased()
        if IPv4Address(customValue) != nil || IPv6Address(customValue) != nil {
            completion(true)
            DispatchQueue.global().async {
                completionDNS(DNSValue(type: .ipAddress, value: customValue, servers: [customValue]))
            }
            return
        } else if let urlHttpsRegex = try? NSRegularExpression(pattern: RegexConstants.urlHttpsRegex),
                  let urlTlsRegex = try? NSRegularExpression(pattern: RegexConstants.urlTlsRegex) {
            let range = NSRange(location: 0, length: customValue.utf16.count)
            if urlHttpsRegex.firstMatch(in: customValue, options: [], range: range) != nil {
                completion(true)
                    DNSSettingsManager.resolveHosts(fromURL: customValue) {
                        completionDNS(DNSValue(type: .overHttps, value: value,
                                               servers: $0))
                    }
                return
            } else if urlTlsRegex.firstMatch(in: customValue, options: [], range: range) != nil {
                completion(true)
                DNSSettingsManager.resolveHosts(fromURL: customValue, isTls: true) {
                    completionDNS(DNSValue(type: .overTLS, value: value, servers: $0))
                }
                return
            }
        }
        completion(false)
        completionDNS(nil)
    }

    private static func resolveHosts(fromURL urlValue: String, isTls: Bool = false, completion: @escaping (_ resolvedHosts: [String]) -> Void) {
        let correctedUrl = isTls ? "https://\(urlValue)" : urlValue
        guard let url = URL(string: correctedUrl), let hostname = url.host else {
            completion([])
            return
        }
        return DNSSettingsManager.resolveHosts(for: hostname, completion: completion)
    }

    private static func resolveHosts(for hostname: String, completion: @escaping (_ resolvedHosts: [String]) -> Void) {
        let timeout: TimeInterval = 5.0
        var flag = true
        var workItem: DispatchWorkItem? = DispatchWorkItem {
            var resolvedHosts = [String]()
            var hints = addrinfo(
                ai_flags: 0,
                ai_family: AF_INET,
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
                return
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
            resolvedHosts = returnHosts
            guard flag else { return }
            completion(resolvedHosts)
            flag = false
        }
        DispatchQueue.global().async(execute: workItem!)
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            guard flag else { return }
            workItem?.cancel()
            workItem = nil
            flag = false
            print("$$$ DNS resolution timed out")
            completion([])

        }
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
