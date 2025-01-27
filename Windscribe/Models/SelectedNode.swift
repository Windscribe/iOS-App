//
//  SelectedNode.swift
//  Windscribe
//
//  Created by Yalcin on 2019-06-12.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import Swinject

struct SelectedNode {
    let countryCode: String
    let dnsHostname: String
    var hostname: String
    let serverAddress: String
    var nickName: String
    var cityName: String
    var staticIPCredentials: StaticIPCredentialsModel?
    var autoPicked: Bool
    var customConfig: CustomConfigModel?
    var wgPublicKey: String?
    var ovpnX509: String?
    var ip3: String?
    var groupId: Int
    var ip1: String?
    var ip2: String?
    var staticIpToConnect: String?
    var logger = Assembler.resolve(FileLogger.self)
    var localDb = Assembler.resolve(LocalDatabase.self)
    init(countryCode: String,
         dnsHostname: String,
         hostname: String,
         serverAddress: String,
         nickName: String,
         cityName: String,
         staticIPCredentials: StaticIPCredentialsModel? = nil,
         autoPicked: Bool = false,
         customConfig: CustomConfigModel? = nil,
         groupId: Int)
    {
        self.countryCode = countryCode
        self.dnsHostname = dnsHostname
        self.hostname = hostname
        self.serverAddress = serverAddress
        self.nickName = nickName
        self.cityName = cityName
        if let username = staticIPCredentials?.username,
           let password = staticIPCredentials?.password
        {
            self.staticIPCredentials = StaticIPCredentialsModel(username: username, password: password)
        }
        self.autoPicked = autoPicked
        self.customConfig = customConfig
        if let groups = localDb.getGroups(),
           let node = groups.filter({ $0.nodes.contains(where: { $0.hostname == hostname }) }).first
        {
            wgPublicKey = node.wgPublicKey
            ovpnX509 = node.ovpnX509
            let selectedNode = node.nodes.first { $0.hostname == hostname }
            if let selectedNode = selectedNode {
                ip1 = selectedNode.ip
                ip2 = selectedNode.ip2
                ip3 = selectedNode.ip3
                self.hostname = selectedNode.hostname
            } else if let bestNode = node.bestNode {
                ip1 = bestNode.ip
                ip2 = bestNode.ip2
                ip3 = bestNode.ip3
                self.hostname = bestNode.hostname
            } else if let firstNode = node.nodes.first {
                ip1 = firstNode.ip
                ip2 = firstNode.ip2
                ip3 = firstNode.ip3
                self.hostname = firstNode.hostname
            }

            logger.logD("Selected Node", "Selected node changed to \(String(describing: self.hostname))")
        }

        if staticIPCredentials != nil {
            if let staticIP = localDb.getStaticIPs()?.filter({ $0.staticIP == nickName }).first {
                wgPublicKey = staticIP.wgPublicKey
                ovpnX509 = staticIP.ovpnX509
                ip1 = staticIP.nodes.first?.ip
                ip2 = staticIP.nodes.first?.ip2
                ip3 = staticIP.wgIp
                staticIpToConnect = staticIP.connectIP
            }
        }
        self.groupId = groupId
    }
}
