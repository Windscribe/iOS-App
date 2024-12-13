//
//  LocalDatabaseImpl+Migration.swift
//  Windscribe
//
//  Created by Andre Fonseca on 12/07/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import RxSwift

extension LocalDatabaseImpl {
    // MARK: migration

    func migrate() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 52,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: Session.className()) { _, _ in }
                } else if oldSchemaVersion < 2 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                    migration.enumerateObjects(ofType: Server.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                } else if oldSchemaVersion < 3 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                } else if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["appearance"] = TextsAsset.appearances[0]
                    }
                } else if oldSchemaVersion < 5 {
                    migration.enumerateObjects(ofType: ReadNotice.className()) { oldObject, newObject in
                        newObject!["id"] = oldObject!["id"]
                    }
                } else if oldSchemaVersion < 6 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject!["SSID"] = TextsAsset.unknownNetworkName
                    }
                } else if oldSchemaVersion < 7 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, _ in }
                } else if oldSchemaVersion < 8 {
                    migration.enumerateObjects(ofType: Node.className()) { _, newObject in
                        newObject!["forceDisconnect"] = false
                    }
                } else if oldSchemaVersion < 9 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, _ in }
                } else if oldSchemaVersion < 10 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                } else if oldSchemaVersion < 11 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                } else if oldSchemaVersion < 12 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                } else if oldSchemaVersion < 13 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                } else if oldSchemaVersion < 14 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                } else if oldSchemaVersion < 15 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                } else if oldSchemaVersion < 16 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, _ in }
                } else if oldSchemaVersion < 17 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, _ in }
                } else if oldSchemaVersion < 18 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, _ in }
                } else if oldSchemaVersion < 19 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, _ in }
                } else if oldSchemaVersion < 20 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject!["preferredProtocolStatus"] = false
                        newObject!["preferredProtocol"] = wireGuard
                        newObject!["preferredPort"] = "443"
                    }
                } else if oldSchemaVersion < 21 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, _ in }
                } else if oldSchemaVersion < 22 {
                    migration.enumerateObjects(ofType: Notice.className()) { _, _ in }
                } else if oldSchemaVersion < 23 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, _ in }
                } else if oldSchemaVersion < 24 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["autoSecureNewNetworks"] = true
                    }
                } else if oldSchemaVersion < 27 {
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, newObject in
                        newObject!["connectedAt"] = Date()
                    }
                } else if oldSchemaVersion < 28 {
                    migration.enumerateObjects(ofType: Group.className()) { _, _ in }
                } else if oldSchemaVersion < 29 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, _ in }
                } else if oldSchemaVersion < 30 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, _ in }
                } else if oldSchemaVersion < 31 {
                    migration.enumerateObjects(ofType: VPNConnection.className()) { _, _ in }
                } else if oldSchemaVersion < 32 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject!["protocolType"] = wireGuard
                        newObject!["port"] = "443"
                    }
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["hapticFeedback"] = true
                    }
                } else if oldSchemaVersion < 33 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["hapticFeedback"] = true
                    }
                } else if oldSchemaVersion < 34 {
                    migration.enumerateObjects(ofType: Node.className()) { _, _ in }
                } else if oldSchemaVersion < 35 {
                    migration.enumerateObjects(ofType: Group.className()) { _, _ in }
                } else if oldSchemaVersion < 36 {
                    migration.enumerateObjects(ofType: BestNode.className()) { _, _ in }
                } else if oldSchemaVersion < 37 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, _ in }
                } else if oldSchemaVersion < 39 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["protocolType"] = wireGuard
                        newObject!["port"] = "443"
                    }
                } else if oldSchemaVersion < 42 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["ovpnX509"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["ovpnX509"] = ""
                    }
                } else if oldSchemaVersion < 43 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["health"] = 0
                        newObject!["linkSpeed"] = "1000"
                    }
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["health"] = 0
                        newObject!["linkSpeed"] = "1000"
                    }
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["showServerHealth"] = false
                    }
                    migration.enumerateObjects(ofType: Notice.className()) { _, newObject in
                        newObject!["permFree"] = false
                        newObject!["permPro"] = false
                        newObject!["action"] = nil
                    }
                    migration.enumerateObjects(ofType: MobilePlan.className()) { _, newObject in
                        newObject!["discount"] = 0
                        newObject!["duration"] = 0
                    }
                } else if oldSchemaVersion < 44 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["killSwitch"] = false
                        newObject!["allowLan"] = false
                    }
                } else if oldSchemaVersion < 45 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject!["wgFailed"] = 0
                        newObject!["wsTunnelFailed"] = 0
                        newObject!["stealthFailed"] = 0
                    }
                } else if oldSchemaVersion < 46 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                } else if oldSchemaVersion < 47 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { oldObject, _ in
                        if let latencyType = oldObject?["latencyType"] as? String {
                            self.preferences.saveLatencyType(latencyType: latencyType)
                        }
                        if let connectionMode = oldObject?["connectionMode"] as? String {
                            self.preferences.saveConnectionMode(mode: connectionMode)
                        }
                        if let language = oldObject?["language"] as? String {
                            self.preferences.saveLanguage(language: language)
                        }
                        if let orderLocationsBy = oldObject?["orderLocationsBy"] as? String {
                            self.preferences.saveOrderLocationsBy(order: orderLocationsBy)
                        }
                        if let appearance = oldObject?["appearance"] as? String {
                            self.preferences.saveAppearance(appearance: appearance)
                        }
                        if let firewall = oldObject?["firewall"] as? Bool {
                            self.preferences.saveFirewallMode(firewall: firewall)
                        }
                        if let killSwitch = oldObject?["killSwitch"] as? Bool {
                            self.preferences.saveKillSwitch(killSwitch: killSwitch)
                        }
                        if let allowLan = oldObject?["allowLan"] as? Bool {
                            self.preferences.saveAllowLane(mode: allowLan)
                        }
                        if let autoSecureNewNetworks = oldObject?["autoSecureNewNetworks"] as? Bool {
                            self.preferences.saveAutoSecureNewNetworks(autoSecure: autoSecureNewNetworks)
                        }
                        if let hapticFeedback = oldObject?["hapticFeedback"] as? Bool {
                            self.preferences.saveHapticFeedback(haptic: hapticFeedback)
                        }
                        if let showServerHealth = oldObject?["showServerHealth"] as? Bool {
                            self.preferences.saveShowServerHealth(show: showServerHealth)
                        }
                        if let protocolType = oldObject?["protocolType"] as? String {
                            self.preferences.saveSelectedProtocol(selectedProtocol: protocolType)
                        }
                        if let port = oldObject?["port"] as? String {
                            self.preferences.saveSelectedPort(port: port)
                        }
                    }
                    migration.enumerateObjects(ofType: PortMap.className()) { _, _ in }
                    migration.enumerateObjects(ofType: PingData.className()) { _, _ in }
                    migration.enumerateObjects(ofType: MyIP.className()) { _, _ in }
                    migration.enumerateObjects(ofType: OpenVPNServerCredentials.className()) { _, newObject in
                        newObject!["id"] = "OpenVPNServerCredentials"
                    }
                    migration.enumerateObjects(ofType: IKEv2ServerCredentials.className()) { _, newObject in
                        newObject!["id"] = "IKEv2ServerCredentials"
                    }
                } else if oldSchemaVersion < 48 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                } else if oldSchemaVersion < 49 {
                    migration.enumerateObjects(ofType: MobilePlan.className()) { _, _ in }
                } else if oldSchemaVersion < 50 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["isPremiumOnly"] = false
                    }
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, newObject in
                        newObject!["isPremiumOnly"] = false
                    }
                } else if oldSchemaVersion < 51 {
                    migration.enumerateObjects(ofType: BestLocation.className()) { _, newObject in
                        newObject?["id"] = "BestLocation"
                    }
                    migration.deleteData(forType: BestLocation.className())
                } else if oldSchemaVersion < 52 {
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { oldObject, _ in
                        if let groupId = oldObject?["groupId"] as? String {
                            self.preferences.saveLastSelectedLocation(with: groupId)
                        }
                    }
                    migration.enumerateObjects(ofType: BestLocation.className()) { oldObject, _ in
                        if let groupId = oldObject?["groupId"] as? String {
                            self.preferences.saveBestLocation(with: groupId)
                        }
                    }
                }
            }, deleteRealmIfMigrationNeeded: false
        )
    }
}
