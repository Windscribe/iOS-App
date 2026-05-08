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

extension LocalDatabaseImpl {
    // MARK: migration
    func migrate() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 63,
            migrationBlock: { migration, oldSchemaVersion in
                let shouldDeleteBestLocation = oldSchemaVersion < 51

                // Realm calls this block once with the original stored schema version,
                // so these checks must be cumulative. Do not change them to else-if.
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: Session.className()) { _, _ in }
                }
                if oldSchemaVersion < 2 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                    migration.enumerateObjects(ofType: Server.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                }
                if oldSchemaVersion < 3 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["id"] = nextID
                        nextID += 1
                    }
                }
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["appearance"] = TextsAsset.appearances[0]
                    }
                }
                if oldSchemaVersion < 5 {
                    migration.enumerateObjects(ofType: ReadNotice.className()) { oldObject, newObject in
                        newObject!["id"] = oldObject!["id"]
                    }
                }
                if oldSchemaVersion < 6 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject!["SSID"] = TextsAsset.unknownNetworkName
                    }
                }
                if oldSchemaVersion < 7 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, _ in }
                }
                if oldSchemaVersion < 8 {
                    migration.enumerateObjects(ofType: Node.className()) { _, newObject in
                        newObject!["forceDisconnect"] = false
                    }
                }
                if oldSchemaVersion < 9 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, _ in }
                }
                if oldSchemaVersion < 10 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                }
                if oldSchemaVersion < 11 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                }
                if oldSchemaVersion < 12 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                }
                if oldSchemaVersion < 13 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                }
                if oldSchemaVersion < 14 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                }
                if oldSchemaVersion < 15 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                }
                if oldSchemaVersion < 16 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, _ in }
                }
                if oldSchemaVersion < 17 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, _ in }
                }
                if oldSchemaVersion < 18 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, _ in }
                }
                if oldSchemaVersion < 19 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, _ in }
                }
                if oldSchemaVersion < 20 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject!["preferredProtocolStatus"] = false
                        newObject!["preferredProtocol"] = wireGuard
                        newObject!["preferredPort"] = "443"
                    }
                }
                if oldSchemaVersion < 21 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, _ in }
                }
                if oldSchemaVersion < 22 {
                    migration.enumerateObjects(ofType: Notice.className()) { _, _ in }
                }
                if oldSchemaVersion < 23 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, _ in }
                }
                if oldSchemaVersion < 24 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["autoSecureNewNetworks"] = true
                    }
                }
                if oldSchemaVersion < 27 {
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, newObject in
                        newObject!["connectedAt"] = Date()
                    }
                }
                if oldSchemaVersion < 28 {
                    migration.enumerateObjects(ofType: Group.className()) { _, _ in }
                }
                if oldSchemaVersion < 29 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, _ in }
                }
                if oldSchemaVersion < 30 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, _ in }
                }
                if oldSchemaVersion < 31 {
                    migration.enumerateObjects(ofType: VPNConnection.className()) { _, _ in }
                }
                if oldSchemaVersion < 32 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject!["protocolType"] = wireGuard
                        newObject!["port"] = "443"
                    }
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["hapticFeedback"] = true
                    }
                }
                if oldSchemaVersion < 33 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["hapticFeedback"] = true
                    }
                }
                if oldSchemaVersion < 34 {
                    migration.enumerateObjects(ofType: Node.className()) { _, _ in }
                }
                if oldSchemaVersion < 35 {
                    migration.enumerateObjects(ofType: Group.className()) { _, _ in }
                }
                if oldSchemaVersion < 36 {
                    migration.enumerateObjects(ofType: BestNode.className()) { _, _ in }
                }
                if oldSchemaVersion < 37 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, _ in }
                }
                if oldSchemaVersion < 39 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["protocolType"] = wireGuard
                        newObject!["port"] = "443"
                    }
                }
                if oldSchemaVersion < 42 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["ovpnX509"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["ovpnX509"] = ""
                    }
                }
                if oldSchemaVersion < 43 {
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
                }
                if oldSchemaVersion < 44 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject!["killSwitch"] = false
                        newObject!["allowLan"] = false
                    }
                }
                if oldSchemaVersion < 45 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject!["wgFailed"] = 0
                        newObject!["wsTunnelFailed"] = 0
                        newObject!["stealthFailed"] = 0
                    }
                }
                if oldSchemaVersion < 46 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                }
                if oldSchemaVersion < 47 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { oldObject, _ in
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
                            self.preferences.saveDarkMode(darkMode: appearance == DefaultValues.appearance)
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
                }
                if oldSchemaVersion < 48 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["pingHost"] = ""
                    }
                }
                if oldSchemaVersion < 49 {
                    migration.enumerateObjects(ofType: MobilePlan.className()) { _, _ in }
                }
                if oldSchemaVersion < 50 {
                    migration.enumerateObjects(ofType: FavNode.className()) { _, newObject in
                        newObject!["isPremiumOnly"] = false
                    }
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, newObject in
                        newObject!["isPremiumOnly"] = false
                    }
                }
                if oldSchemaVersion < 51 {
                    migration.enumerateObjects(ofType: BestLocation.className()) { _, newObject in
                        newObject?["id"] = "BestLocation"
                    }
                }
                if oldSchemaVersion < 52 {
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { oldObject, _ in
                        if let groupId = oldObject?["groupId"] as? String {
                            self.preferences.saveLastSelectedLocation(with: groupId)
                        }
                    }
                    migration.enumerateObjects(ofType: BestLocation.className()) { oldObject, _ in
                        if let groupId = oldObject?["groupId"] as? String {
                            self.preferences.saveBestLocation(with: groupId)
                        } else if let groupId = oldObject?["groupId"] as? Int {
                            self.preferences.saveBestLocation(with: String(groupId))
                        }
                    }
                }
                if shouldDeleteBestLocation {
                    // Delete after the v52 preference migration has had a chance to read old rows.
                    migration.deleteData(forType: BestLocation.className())
                }
                if oldSchemaVersion < 53 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject!["expiry"] = nil
                        newObject!["isActive"] = true
                        newObject!["pingIP"] = ""
                    }
                }
                if oldSchemaVersion < 55 {
                    var favSet = Set<String>()
                    // Will try to see if FavNodes were already migrated to Favourites
                    migration.enumerateObjects(ofType: Favourite.className()) { oldObject, _ in
                        guard let id = oldObject?["id"] as? String else { return }
                        favSet.insert(id)
                    }
                    if favSet.count == 0 {
                        // Due to a previous migration error FavNodes were not migrated to Favourites
                        // We need to do it now
                        migration.enumerateObjects(ofType: FavNode.className()) { oldObject, _ in
                            guard let id = oldObject?["groupId"] as? String else { return }
                            if !favSet.contains(id) {
                                favSet.insert(id)
                                migration.create(Favourite.className(), value: ["id": id])
                            }
                        }
                    }
                }
                if oldSchemaVersion < 56 {
                    migration.enumerateObjects(ofType: Favourite.className()) { _, newObject in
                        newObject?["pinnedIp"] = nil
                        newObject?["pinnedNodeHostname"] = nil
                    }
                }
                if oldSchemaVersion < 57 {
                    migration.enumerateObjects(ofType: LastConnectedNode.className()) { _, _ in }
                }
                if oldSchemaVersion < 58 {
                    migration.enumerateObjects(ofType: SipCount.className()) { _, _ in }
                }
                if oldSchemaVersion < 59 {
                    // Delete deprecated FavNode and LastConnectedNode data
                    // These were migrated to Favourite in version 55
                    migration.deleteData(forType: FavNode.className())
                    migration.deleteData(forType: LastConnectedNode.className())
                }
                if oldSchemaVersion < 61 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, newObject in
                        newObject!["saveCredentials"] = true
                    }
                }
                if oldSchemaVersion < 62 {
                    // Add new server architecture tables
                    migration.enumerateObjects(ofType: LocationObject.className()) { _, _ in }
                    migration.enumerateObjects(ofType: DatacenterObject.className()) { _, _ in }
                    migration.enumerateObjects(ofType: ServerMachineObject.className()) { _, _ in }
                    // Add/update UnblockWgParamsObj schema with new properties
                    migration.enumerateObjects(ofType: UnblockWgParamsObj.className()) { _, newObject in
                        // Add new properties with default values if they don't exist
                        newObject!["title"] = ""
                        newObject!["h1"] = nil
                        newObject!["h2"] = nil
                        newObject!["h3"] = nil
                        newObject!["h4"] = nil
                        newObject!["i1"] = nil
                        newObject!["i2"] = nil
                        newObject!["i3"] = nil
                        newObject!["i4"] = nil
                        newObject!["i5"] = nil
                    }
                    // Remove duplicates by deleting all and letting them be re-fetched from API
                    migration.deleteData(forType: UnblockWgParamsObj.className())
                }
                if oldSchemaVersion < 63 {
                    // Delete deprecated OldSession. Class no longer exists in code; reference by name.
                    migration.deleteData(forType: "OldSession")
                }
            }, deleteRealmIfMigrationNeeded: false
        )
    }

    var doNotDeleteObjects: [String] { [String(describing: Favourite.self)] }
}
