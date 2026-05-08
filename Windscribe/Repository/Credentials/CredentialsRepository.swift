//
//  CredentialsRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol CredentialsRepository: Sendable {
    var openVPNCrendentials: ServerCredentialsModel? { get }
    var ikev2Crendentials: ServerCredentialsModel? { get }

    func getUpdatedOpenVPNCrendentials() async throws
    func getUpdatedIKEv2Crendentials() async throws
    func getUpdatedServerConfig() async throws
    func selectedServerCredentialsType() -> ServerCredentials.Type
    func updateServerConfig()
}
