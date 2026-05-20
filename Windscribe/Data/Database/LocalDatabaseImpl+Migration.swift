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
        var configuration = Realm.Configuration(
            schemaVersion: 64,
            migrationBlock: { migration, oldSchemaVersion in

                // Realm calls this block once with the original stored schema version,
                // so these checks must be cumulative. Do not change them to else-if.
                if oldSchemaVersion < 1 {
                    migration.enumerateObjects(ofType: Session.className()) { _, _ in }
                }
                if oldSchemaVersion < 2 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject?["id"] = nextID
                        nextID += 1
                    }
                    migration.enumerateObjects(ofType: Server.className()) { _, newObject in
                        newObject?["id"] = nextID
                        nextID += 1
                    }
                }
                if oldSchemaVersion < 3 {
                    var nextID = 0
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject?["id"] = nextID
                        nextID += 1
                    }
                }
                if oldSchemaVersion < 4 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject?["appearance"] = TextsAsset.appearances[0]
                    }
                }
                if oldSchemaVersion < 5 {
                    migration.enumerateObjects(ofType: ReadNotice.className()) { oldObject, newObject in
                        newObject?["id"] = oldObject?["id"]
                    }
                }
                if oldSchemaVersion < 6 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject?["SSID"] = TextsAsset.unknownNetworkName
                    }
                }
                if oldSchemaVersion < 8 {
                    migration.enumerateObjects(ofType: Node.className()) { _, newObject in
                        newObject?["forceDisconnect"] = false
                    }
                }
                if oldSchemaVersion < 16 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, _ in }
                }
                if oldSchemaVersion < 20 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject?["preferredProtocolStatus"] = false
                        newObject?["preferredProtocol"] = VPNProtocolType.wireGuard.identifier
                        newObject?["preferredPort"] = "443"
                    }
                }
                if oldSchemaVersion < 24 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject?["autoSecureNewNetworks"] = true
                    }
                }
                if oldSchemaVersion < 31 {
                    migration.enumerateObjects(ofType: VPNConnection.className()) { _, _ in }
                }
                if oldSchemaVersion < 32 {
                    migration.enumerateObjects(ofType: WifiNetwork.className()) { _, newObject in
                        newObject?["protocolType"] = VPNProtocolType.wireGuard.identifier
                        newObject?["port"] = "443"
                    }
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject?["hapticFeedback"] = true
                    }
                }
                if oldSchemaVersion < 33 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject?["hapticFeedback"] = true
                    }
                }
                if oldSchemaVersion < 34 {
                    migration.enumerateObjects(ofType: Node.className()) { _, _ in }
                }
                if oldSchemaVersion < 36 {
                    migration.enumerateObjects(ofType: BestNode.className()) { _, _ in }
                }
                if oldSchemaVersion < 39 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject?["protocolType"] = VPNProtocolType.wireGuard.identifier
                        newObject?["port"] = "443"
                    }
                }
                if oldSchemaVersion < 42 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject?["ovpnX509"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject?["ovpnX509"] = ""
                    }
                }
                if oldSchemaVersion < 43 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject?["health"] = 0
                        newObject?["linkSpeed"] = "1000"
                    }
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject?["showServerHealth"] = false
                    }
                    migration.enumerateObjects(ofType: Notice.className()) { _, newObject in
                        newObject?["permFree"] = false
                        newObject?["permPro"] = false
                        newObject?["action"] = nil
                    }
                    migration.enumerateObjects(ofType: MobilePlan.className()) { _, newObject in
                        newObject?["discount"] = 0
                        newObject?["duration"] = 0
                    }
                }
                if oldSchemaVersion < 44 {
                    migration.enumerateObjects(ofType: UserPreferences.className()) { _, newObject in
                        newObject?["killSwitch"] = false
                        newObject?["allowLan"] = false
                    }
                }
                if oldSchemaVersion < 45 {
                    migration.enumerateObjects(ofType: AutomaticMode.className()) { _, newObject in
                        newObject?["wgFailed"] = 0
                        newObject?["wsTunnelFailed"] = 0
                        newObject?["stealthFailed"] = 0
                    }
                }
                if oldSchemaVersion < 46 {
                    migration.enumerateObjects(ofType: Group.className()) { _, newObject in
                        newObject?["pingHost"] = ""
                    }
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject?["pingHost"] = ""
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
                        newObject?["id"] = "OpenVPNServerCredentials"
                    }
                    migration.enumerateObjects(ofType: IKEv2ServerCredentials.className()) { _, newObject in
                        newObject?["id"] = "IKEv2ServerCredentials"
                    }
                }
                if oldSchemaVersion < 49 {
                    migration.enumerateObjects(ofType: MobilePlan.className()) { _, _ in }
                }
                if oldSchemaVersion < 52 {
                    migration.enumerateObjects(ofType: BestLocation.className()) { oldObject, _ in
                        if let groupId = oldObject?["groupId"] as? String {
                            self.preferences.saveBestLocation(with: groupId)
                        } else if let groupId = oldObject?["groupId"] as? Int {
                            self.preferences.saveBestLocation(with: String(groupId))
                        }
                    }
                    migration.deleteData(forType: BestLocation.className())
                }
                if oldSchemaVersion < 53 {
                    migration.enumerateObjects(ofType: StaticIP.className()) { _, newObject in
                        newObject?["expiry"] = nil
                        newObject?["isActive"] = true
                        newObject?["pingIP"] = ""
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
                        newObject?["pinnedNodeIp"] = nil
                    }
                }
                if oldSchemaVersion < 58 {
                    migration.enumerateObjects(ofType: SipCount.className()) { _, _ in }
                }
                if oldSchemaVersion < 59 {
                    // FavNode and LastConnectedNode data was migrated to Favourite in v55.
                    // LastConnectedNode is no longer in objectTypes, so deleteData(forType:)
                    // would crash iOS 16 via objc_copyClassList — leave its orphan table.
                    migration.deleteData(forType: FavNode.className())
                }
                if oldSchemaVersion < 61 {
                    migration.enumerateObjects(ofType: CustomConfig.className()) { _, newObject in
                        newObject?["saveCredentials"] = true
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
                        newObject?["title"] = ""
                        newObject?["h1"] = nil
                        newObject?["h2"] = nil
                        newObject?["h3"] = nil
                        newObject?["h4"] = nil
                        newObject?["i1"] = nil
                        newObject?["i2"] = nil
                        newObject?["i3"] = nil
                        newObject?["i4"] = nil
                        newObject?["i5"] = nil
                    }
                    // Remove duplicates by deleting all and letting them be re-fetched from API
                    migration.deleteData(forType: UnblockWgParamsObj.className())
                }
                // v63 previously called migration.deleteData(forType: "OldSession") here;
                // OldSession isn't in objectTypes, so that crashes iOS 16 via
                // objc_copyClassList. Realm silently ignores the orphan table.
            }, deleteRealmIfMigrationNeeded: false
        )
        // Pin the schema to an explicit class list. Prevents Realm from
        // calling objc_copyClassList() during +sharedSchema, which forces
        // Swift metadata realization for every class in the binary —
        // including @available-gated classes whose metadata depends on
        // weakly-linked frameworks (e.g. @Observable on iOS 16).
        // Note: migration.deleteData(forType:) and enumerateObjects(ofType:)
        // hit the same objc_copyClassList path for any name absent from this
        // list (their schemaForClassName lookup misses the fast cache and
        // falls through to +classForString:). Never call them with class
        // names that aren't here — orphan tables on disk are harmless.
        configuration.objectTypes = [
            Session.self,
            SipCount.self,
            UserPreferences.self,
            LocationObject.self,
            DatacenterObject.self,
            ServerMachineObject.self,
            Server.self,
            Group.self,
            Info.self,
            Node.self,
            BestNode.self,
            BestLocation.self,
            StaticIP.self,
            StaticIPNode.self,
            PortDetails.self,
            Favourite.self,
            FavNode.self,
            WifiNetwork.self,
            AutomaticMode.self,
            Notice.self,
            NoticeAction.self,
            ReadNotice.self,
            VPNConnection.self,
            CustomConfig.self,
            PortMap.self,
            SuggestedPorts.self,
            UnblockWgParamsObj.self,
            PingData.self,
            MyIP.self,
            MobilePlan.self,
            RobertFilters.self,
            RobertFilter.self,
            ServerCredentials.self,
            OpenVPNServerCredentials.self,
            IKEv2ServerCredentials.self,
            StaticIPCredentials.self
        ]
        Realm.Configuration.defaultConfiguration = configuration
    }

    var doNotDeleteObjects: [String] { [String(describing: Favourite.self)] }
}
