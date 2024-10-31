import XCTest
import Swinject
import RxSwift
import Mockingbird
@testable import Windscribe

final class ConfigurationsManagerTests: XCTestCase {
    var configManager: ConfigurationsManager?
    let disposeBag = DisposeBag()
    var db: LocalDatabase?

    var logger: FileLogger {
        return Assembler.resolve(FileLogger.self)
    }
    override func setUp() {
        db = Assembler.resolve(LocalDatabase.self)
        configManager = Assembler.resolve(ConfigurationsManager.self)
        super.setUp()
    }

    override func tearDown() {
        db?.clean()
        configManager = nil
        super.tearDown()
    }

    private func addLocation() {
        let json = """
        {
            "data": [
                {
                    "id": 65,
                    "name": "US Central",
                    "country_code": "US",
                    "status": 1,
                    "premium_only": 0,
                    "short_name": "US-C",
                    "p2p": 1,
                    "tz": "America Chicago",
                    "tz_offset": "-6,CST",
                    "loc_type": "normal",
                    "force_expand": 1,
                    "dns_hostname": "us-central.windscribe.com",
                    "groups": [
                        {
                            "id": 109,
                            "city": "Atlanta",
                            "nick": "Mountain",
                            "pro": 0,
                            "gps": "33.75,-84.39",
                            "tz": "America New_York",
                            "wg_pubkey": "D2Tx/zEgTy2uoH2HLp5EBIFyLkHGEhkhLMYYedpcUFw=",
                            "wg_endpoint": "atl-109-wg.whiskergalaxy.com",
                            "ovpn_x509": "atl-109.windscribe.com",
                            "ping_ip": "155.94.217.66",
                            "ping_host": "https:us-central-091.whiskergalaxy.com:6363/latency",
                            "link_speed": "10000",
                            "nodes": [
                                {
                                    "ip": "155.94.216.2",
                                    "ip2": "155.94.216.3",
                                    "ip3": "155.94.216.4",
                                    "hostname": "us-central-093.whiskergalaxy.com",
                                    "weight": 1,
                                    "health": 64
                                },
                                {
                                    "ip": "198.44.138.43",
                                    "ip2": "198.44.138.44",
                                    "ip3": "198.44.138.45",
                                    "hostname": "us-central-116.whiskergalaxy.com",
                                    "weight": 2,
                                    "health": 10
                                }
                            ],
                            "health": 49
                        }
                    ]
                }
            ],
        "info": {
        "revision": 43773,
        "revision_hash": "21a7adab263d584d8f3e5411e1641f338251a309",
        "changed": 1,
        "fc": 1,
        "pro_datacenters": []
        }
        }
        """
        do {
            let servers = try JSONDecoder().decode(ServerList.self, from: json.utf8Encoded)
            db!.saveServers(servers: servers.servers.toArray())
        } catch {
            XCTFail("Failed to decode server list: \(error)")
        }
    }

    private func addCredentials() {
        let json = """
        {
            "data": {
                "username": "-x-x-x-x-x-x-x--x",
                "password": "-x-x-x-x-x-x-x--x"
            }
        }
        """
        do {
            let creds = try JSONDecoder().decode(IKEv2ServerCredentials.self, from: json.utf8Encoded)
            db!.saveIKEv2ServerCredentials(credentials: creds).disposed(by: disposeBag)
        } catch {
            XCTFail("Failed to decode server list: \(error)")
        }
    }

    func testConnectAsync_buildConfigSuccess() async {
        addCredentials()
        addLocation()
        let locationID = "109"
        let proto = TextsAsset.wireGuard
        let port = "443"
        let userSettings = VPNUserSettings(killSwitch: false, allowLane: true, isRFC: true, isCircumventCensorshipEnabled: true, onDemandRules: [])

        do {
          //  try await Task.sleep(nanoseconds: 2_000_000_000)
            let config = try await configManager?.buildConfig(location: locationID, proto: proto, port: port, userSettings: userSettings)
            if let wg = config as? WireguardVPNConfiguration {
                logger.logD(self, "Config: \(wg.description)")
            }

            XCTAssertNotNil(config, "VPN configuration should be built successfully.")
        } catch let e {
            if let error = e as? VPNConfigurationErrors {
                XCTFail("Expected configuration to build successfully, but error occurred: \(error.errorDescription)")
            }

        }
    }
}

