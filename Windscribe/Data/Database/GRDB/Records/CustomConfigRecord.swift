import Foundation
import GRDB

/// GRDB row type for the `custom_config` table.
struct CustomConfigRecord: Codable, FetchableRecord, PersistableRecord, Equatable {

    static let databaseTableName = Tables.customConfig

    // MARK: - Columns

    let id: String
    let name: String?
    let serverAddress: String?
    let protocolType: String?
    let port: String?
    let username: String?
    let password: String?
    let authRequired: Bool?
    let saveCredentials: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case serverAddress   = "server_address"
        case protocolType    = "protocol_type"
        case port
        case username
        case password
        case authRequired    = "auth_required"
        case saveCredentials = "save_credentials"
    }

    // MARK: - Domain ↔ Record

    init(from model: CustomConfigModel) {
        id              = model.id
        name            = model.name
        serverAddress   = model.serverAddress
        protocolType    = model.protocolType
        port            = model.port
        username        = model.username
        password        = model.password
        authRequired    = model.authRequired
        saveCredentials = model.saveCredentials
    }

    func toModel() -> CustomConfigModel {
        CustomConfigModel(
            id:              id,
            name:            name ?? "",
            serverAddress:   serverAddress ?? "",
            protocolType:    protocolType ?? "",
            port:            port ?? "",
            username:        username ?? "",
            password:        password ?? "",
            authRequired:    authRequired ?? false,
            saveCredentials: saveCredentials ?? true
        )
    }
}
