import Foundation
import GRDB

/// GRDB row type for the `wifi_network` table.
struct WifiNetworkRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.wifiNetwork

    // MARK: - Columns

    /// Primary key. Column is `ssid`; model uses `SSID`.
    let ssid: String
    let status: Bool?
    let protocolType: String?
    let port: String?
    let preferredProtocolStatus: Bool?
    let preferredProtocol: String?
    let preferredPort: String?
    let popupDismissCount: Int?
    let dontAskAgainForPreferredProtocol: Bool?

    enum CodingKeys: String, CodingKey {
        case ssid
        case status
        case protocolType                    = "protocol_type"
        case port
        case preferredProtocolStatus         = "preferred_protocol_status"
        case preferredProtocol               = "preferred_protocol"
        case preferredPort                   = "preferred_port"
        case popupDismissCount               = "popup_dismiss_count"
        case dontAskAgainForPreferredProtocol = "dont_ask_again_for_preferred_protocol"
    }

    // MARK: - Domain ↔ Record

    init(from model: WifiNetworkModel) {
        ssid                             = model.SSID
        status                           = model.status
        protocolType                     = model.protocolType
        port                             = model.port
        preferredProtocolStatus          = model.preferredProtocolStatus
        preferredProtocol                = model.preferredProtocol
        preferredPort                    = model.preferredPort
        popupDismissCount                = model.popupDismissCount
        dontAskAgainForPreferredProtocol = model.dontAskAgainForPreferredProtocol
    }

    func toModel() -> WifiNetworkModel {
        var m = WifiNetworkModel(
            SSID:                    ssid,
            status:                  status ?? false,
            protocolType:            protocolType ?? "",
            port:                    port ?? "",
            preferredProtocol:       preferredProtocol ?? "",
            preferredPort:           preferredPort ?? "",
            preferredProtocolStatus: preferredProtocolStatus ?? false
        )
        m.popupDismissCount                = popupDismissCount ?? 0
        m.dontAskAgainForPreferredProtocol = dontAskAgainForPreferredProtocol ?? false
        return m
    }
}
